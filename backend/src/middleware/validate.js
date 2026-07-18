// -----------------------------------------------------------------------------
// Request validation middleware backed by zod.
//
// Pass a schema object describing any of body / query / params. On success the
// *parsed* (and coerced) values replace the originals, so downstream handlers
// get clean, typed data. On failure we throw a 400 ApiError with the issues.
//
// Usage:
//   router.post('/', validate({ body: createTaskSchema }), handler)
// -----------------------------------------------------------------------------
import { ZodError } from 'zod';
import { ApiError } from '../utils/ApiError.js';

export function validate(schemas) {
  return (req, _res, next) => {
    try {
      if (schemas.params) req.params = schemas.params.parse(req.params);
      if (schemas.query) {
        // req.query is a getter-only property on newer Express; assign parsed
        // values onto a fresh object we control instead of reassigning it.
        req.validatedQuery = schemas.query.parse(req.query);
      }
      if (schemas.body) req.body = schemas.body.parse(req.body);
      return next();
    } catch (err) {
      if (err instanceof ZodError) {
        return next(
          ApiError.badRequest('Validation failed', {
            code: 'VALIDATION_ERROR',
            details: err.issues.map((i) => ({
              path: i.path.join('.'),
              message: i.message,
            })),
          }),
        );
      }
      return next(err);
    }
  };
}
