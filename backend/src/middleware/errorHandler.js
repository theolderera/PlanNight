// -----------------------------------------------------------------------------
// Central error handler + 404 handler.
//
// Every error thrown in a route (via asyncHandler / next(err)) ends up here and
// is turned into a consistent JSON shape:
//   { error: { message, code?, details? } }
//
// Known ApiErrors are trusted and passed through. Anything else is treated as an
// unexpected bug: logged in full, but reported to the client as a generic 500 so
// we never leak internals.
// -----------------------------------------------------------------------------
import { ApiError } from '../utils/ApiError.js';
import { isProduction } from '../config/env.js';

// 404 for unmatched routes. Placed after all routes, before errorHandler.
export function notFoundHandler(req, _res, next) {
  next(ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`));
}

// eslint-disable-next-line no-unused-vars -- Express needs the 4-arg signature.
export function errorHandler(err, _req, res, _next) {
  // Translate a couple of common low-level errors into clean responses.
  if (err?.code === '23505') {
    // Postgres unique_violation — e.g. duplicate email / category name.
    err = ApiError.conflict('That value already exists.', { code: 'DUPLICATE' });
  }

  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: {
        message: err.message,
        ...(err.code ? { code: err.code } : {}),
        ...(err.details ? { details: err.details } : {}),
      },
    });
  }

  // Unexpected: log the real thing, hide details from the client.
  console.error('Unhandled error:', err);
  return res.status(500).json({
    error: {
      message: 'Internal server error',
      ...(isProduction ? {} : { debug: String(err?.message ?? err) }),
    },
  });
}
