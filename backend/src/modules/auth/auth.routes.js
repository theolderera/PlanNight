// -----------------------------------------------------------------------------
// Auth routes: /auth/register, /auth/login, /auth/refresh
//
// A dedicated, stricter rate limiter guards these endpoints against brute-force
// credential stuffing.
// -----------------------------------------------------------------------------
import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import * as controller from './auth.controller.js';
import { registerSchema, loginSchema, refreshSchema } from './auth.validation.js';

const router = Router();

// Max 20 auth attempts per IP per 15 minutes.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: { message: 'Too many attempts, please try again later.' } },
});

router.post('/register', authLimiter, validate({ body: registerSchema }), asyncHandler(controller.register));
router.post('/login', authLimiter, validate({ body: loginSchema }), asyncHandler(controller.login));
router.post('/refresh', authLimiter, validate({ body: refreshSchema }), asyncHandler(controller.refresh));
// Revokes the presented refresh token server-side (rotation table), so a
// logged-out session can't mint new access tokens. Always 204 (idempotent).
router.post('/logout', authLimiter, validate({ body: refreshSchema }), asyncHandler(controller.logout));

export default router;
