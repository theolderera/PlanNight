// -----------------------------------------------------------------------------
// JWT helpers.
//
// We issue two tokens:
//   * access token  — short-lived (minutes), sent on every request.
//   * refresh token — long-lived (days), exchanged for a new access token.
//
// They are signed with DIFFERENT secrets so a leaked access secret cannot be
// used to mint refresh tokens. The `type` claim is checked on verification so an
// access token can never be used where a refresh token is expected, or vice
// versa.
// -----------------------------------------------------------------------------
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export function signAccessToken(userId) {
  return jwt.sign({ sub: userId, type: 'access' }, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
  });
}

/**
 * Sign a refresh token carrying a `jti` (token id). The jti is what the
 * `refresh_tokens` table tracks, enabling rotation and revocation — a refresh
 * token without a matching live row is rejected even if its signature is valid.
 */
export function signRefreshToken(userId, jti) {
  return jwt.sign({ sub: userId, type: 'refresh', jti }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
  });
}

/** Read a token's payload WITHOUT verifying — for expiry bookkeeping only. */
export function decodeToken(token) {
  return jwt.decode(token);
}

/** Verify an access token, returning its payload or throwing. */
export function verifyAccessToken(token) {
  const payload = jwt.verify(token, env.JWT_ACCESS_SECRET);
  if (payload.type !== 'access') throw new Error('Not an access token');
  return payload;
}

/** Verify a refresh token, returning its payload or throwing. */
export function verifyRefreshToken(token) {
  const payload = jwt.verify(token, env.JWT_REFRESH_SECRET);
  if (payload.type !== 'refresh') throw new Error('Not a refresh token');
  return payload;
}

// NOTE: pair issuing lives in auth.service (`issueTokens`) because a refresh
// token is only valid together with its DB row — signing alone is not enough.
