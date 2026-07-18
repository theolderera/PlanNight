// -----------------------------------------------------------------------------
// Auth business logic: register, login, refresh (with rotation), logout.
// Kept separate from the HTTP controller so it is easy to test and reuse.
//
// Refresh tokens are stateful: every issued token has a `refresh_tokens` row
// keyed by its `jti` claim (see migration 003). A token is honoured only while
// its row exists, is unrevoked and unexpired. Refresh rotates (old jti revoked,
// new pair issued); logout revokes. So "log out" now actually ends the session
// server-side instead of merely forgetting tokens on the device.
// -----------------------------------------------------------------------------
import { randomUUID } from 'node:crypto';

import { query } from '../../config/db.js';
import { hashPassword, verifyPassword } from '../../utils/password.js';
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  decodeToken,
} from '../../utils/jwt.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeUser } from '../users/user.serializer.js';

/**
 * Issue an access + refresh pair, recording the refresh token's jti so it can
 * later be rotated or revoked. The row's expiry mirrors the JWT's own `exp`.
 */
async function issueTokens(userId) {
  const jti = randomUUID();
  const refreshToken = signRefreshToken(userId, jti);
  const { exp } = decodeToken(refreshToken); // seconds since epoch

  await query(
    `INSERT INTO refresh_tokens (id, user_id, expires_at)
     VALUES ($1, $2, to_timestamp($3))`,
    [jti, userId, exp],
  );

  return { accessToken: signAccessToken(userId), refreshToken };
}

/** Opportunistic cleanup: long-expired rows are dead weight, drop them. */
function purgeExpired(userId) {
  // Fire-and-forget; a failed purge must never fail the request.
  query(
    `DELETE FROM refresh_tokens
     WHERE user_id = $1 AND expires_at < now() - interval '7 days'`,
    [userId],
  ).catch(() => {});
}

// A REAL bcrypt hash of a throwaway password, at the configured work factor.
//
// When the email doesn't exist we still run a full bcrypt comparison against
// this, so a login attempt costs the same either way. A hand-written constant
// would NOT work: bcrypt rejects a malformed hash in ~0ms instead of doing the
// ~hundreds of ms of real work, which is exactly the timing difference that
// lets an attacker enumerate which emails are registered.
//
// Built lazily on first use (hashing at import time would slow every startup)
// and memoised thereafter.
let dummyHashPromise;
function getDummyHash() {
  dummyHashPromise ??= hashPassword('password-that-is-never-valid');
  return dummyHashPromise;
}

/**
 * Create a new user account and return { user, tokens }.
 * Throws 409 if the email is already registered.
 */
export async function register({ email, password, timezone, language }) {
  const passwordHash = await hashPassword(password);

  let row;
  try {
    const result = await query(
      `INSERT INTO users (email, password_hash, timezone, language)
       VALUES ($1, $2, COALESCE($3, 'UTC'), COALESCE($4, 'en'))
       RETURNING *`,
      [email, passwordHash, timezone ?? null, language ?? null],
    );
    row = result.rows[0];
  } catch (err) {
    if (err.code === '23505') {
      throw ApiError.conflict('An account with this email already exists.', {
        code: 'EMAIL_TAKEN',
      });
    }
    throw err;
  }

  return { user: serializeUser(row), tokens: await issueTokens(row.id) };
}

/**
 * Verify credentials and return { user, tokens }.
 * Uses a single generic error for "no such email" and "wrong password" so we
 * don't reveal which emails are registered.
 */
export async function login({ email, password }) {
  const { rows } = await query(
    'SELECT * FROM users WHERE lower(email) = lower($1)',
    [email],
  );
  const row = rows[0];

  // Always run a hash comparison to keep timing roughly constant whether or not
  // the email exists (mitigates user-enumeration via response time).
  const hash = row ? row.password_hash : await getDummyHash();
  const passwordMatches = await verifyPassword(password, hash);

  if (!row || !passwordMatches) {
    throw ApiError.unauthorized('Invalid email or password.', { code: 'BAD_CREDENTIALS' });
  }

  purgeExpired(row.id);
  return { user: serializeUser(row), tokens: await issueTokens(row.id) };
}

/**
 * Exchange a valid refresh token for a fresh pair, revoking the presented one
 * (rotation). Rejected when the signature is bad, the jti has no live row
 * (pre-migration token, already rotated, or logged out), or the user is gone.
 *
 * Deliberately NO revoke-all-on-reuse: a mobile client that lost the rotation
 * response on a flaky network legitimately retries with the old token, and
 * nuking every session for that would hurt more than it protects here.
 */
export async function refresh({ refreshToken }) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw ApiError.unauthorized('Invalid or expired refresh token.', { code: 'REFRESH_INVALID' });
  }
  if (!payload.jti) {
    // Pre-rotation token (no jti): force a clean re-login.
    throw ApiError.unauthorized('Invalid or expired refresh token.', { code: 'REFRESH_INVALID' });
  }

  // Atomically revoke the presented token IF it is still live. Zero rows means
  // it was already rotated/revoked/expired — reject without side effects.
  const { rows } = await query(
    `UPDATE refresh_tokens SET revoked_at = now()
     WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL AND expires_at > now()
     RETURNING id`,
    [payload.jti, payload.sub],
  );
  if (rows.length === 0) {
    throw ApiError.unauthorized('Invalid or expired refresh token.', { code: 'REFRESH_INVALID' });
  }

  // Ensure the user still exists before minting new tokens.
  const user = await query('SELECT id FROM users WHERE id = $1', [payload.sub]);
  if (user.rows.length === 0) {
    throw ApiError.unauthorized('User no longer exists.', { code: 'USER_GONE' });
  }

  purgeExpired(payload.sub);
  return { tokens: await issueTokens(payload.sub) };
}

/**
 * End the session the presented refresh token belongs to. Idempotent and
 * deliberately quiet: an invalid/already-revoked token still returns success,
 * because the caller's goal ("this token must not work anymore") is met either
 * way — and error details would only help an attacker probe tokens.
 */
export async function logout({ refreshToken }) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    return; // signature invalid/expired — nothing to revoke
  }
  if (!payload.jti) return;

  await query(
    `UPDATE refresh_tokens SET revoked_at = now()
     WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL`,
    [payload.jti, payload.sub],
  );
}
