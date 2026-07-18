// -----------------------------------------------------------------------------
// Authentication guard. Reads the Bearer access token from the Authorization
// header, verifies it, and attaches { id } to req.user. Routes mounted behind
// this middleware can trust req.user.id.
// -----------------------------------------------------------------------------
import { verifyAccessToken } from '../utils/jwt.js';
import { ApiError } from '../utils/ApiError.js';

export function requireAuth(req, _res, next) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(ApiError.unauthorized('Missing or malformed Authorization header'));
  }

  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub };
    return next();
  } catch {
    // Covers expired, malformed, or wrong-type tokens.
    return next(ApiError.unauthorized('Invalid or expired access token', { code: 'TOKEN_INVALID' }));
  }
}
