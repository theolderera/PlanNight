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

export function signRefreshToken(userId) {
  return jwt.sign({ sub: userId, type: 'refresh' }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
  });
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

/** Issue a fresh access + refresh pair for a user id. */
export function issueTokenPair(userId) {
  return {
    accessToken: signAccessToken(userId),
    refreshToken: signRefreshToken(userId),
  };
}
