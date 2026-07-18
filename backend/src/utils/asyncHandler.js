// -----------------------------------------------------------------------------
// Express (v4) does not catch rejected promises from async route handlers, so an
// unhandled `await` rejection would hang the request. Wrapping a handler in
// asyncHandler forwards any thrown/rejected error to next() -> errorHandler.
//
// Usage:  router.get('/', asyncHandler(async (req, res) => { ... }))
// -----------------------------------------------------------------------------
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
