// -----------------------------------------------------------------------------
// A small operational-error type. Throwing an ApiError anywhere in a request
// lifecycle lets the central error handler turn it into a clean JSON response
// with the right HTTP status, instead of leaking a 500 + stack trace.
// -----------------------------------------------------------------------------
export class ApiError extends Error {
  /**
   * @param {number} statusCode  HTTP status, e.g. 404.
   * @param {string} message     Human-readable message safe to send to clients.
   * @param {object} [options]
   * @param {string} [options.code]     Stable machine-readable code, e.g. 'EMAIL_TAKEN'.
   * @param {any}    [options.details]   Optional extra info (e.g. validation issues).
   */
  constructor(statusCode, message, { code, details } = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    // Marks errors we deliberately threw vs. unexpected bugs.
    this.isOperational = true;
    Error.captureStackTrace?.(this, this.constructor);
  }

  static badRequest(message, opts) { return new ApiError(400, message, opts); }
  static unauthorized(message = 'Unauthorized', opts) { return new ApiError(401, message, opts); }
  static forbidden(message = 'Forbidden', opts) { return new ApiError(403, message, opts); }
  static notFound(message = 'Not found', opts) { return new ApiError(404, message, opts); }
  static conflict(message, opts) { return new ApiError(409, message, opts); }
}
