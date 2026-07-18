// -----------------------------------------------------------------------------
// Auth business logic: register, login, refresh. Kept separate from the HTTP
// controller so it is easy to test and reuse.
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { hashPassword, verifyPassword } from '../../utils/password.js';
import { issueTokenPair, verifyRefreshToken } from '../../utils/jwt.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeUser } from '../users/user.serializer.js';

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

  return { user: serializeUser(row), tokens: issueTokenPair(row.id) };
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

  return { user: serializeUser(row), tokens: issueTokenPair(row.id) };
}

/**
 * Exchange a valid refresh token for a fresh access + refresh pair.
 * (Stateless rotation: we trust any unexpired, correctly-signed refresh token.
 * A future hardening step would be to persist a token id / version per user and
 * revoke on logout — noted in the README.)
 */
export async function refresh({ refreshToken }) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw ApiError.unauthorized('Invalid or expired refresh token.', { code: 'REFRESH_INVALID' });
  }

  // Ensure the user still exists (and isn't deleted) before minting new tokens.
  const { rows } = await query('SELECT id FROM users WHERE id = $1', [payload.sub]);
  if (rows.length === 0) {
    throw ApiError.unauthorized('User no longer exists.', { code: 'USER_GONE' });
  }

  return { tokens: issueTokenPair(payload.sub) };
}
