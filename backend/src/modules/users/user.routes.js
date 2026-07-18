// -----------------------------------------------------------------------------
// User routes: /users/me  (GET profile, PATCH settings)
// All routes require authentication (mounted behind requireAuth in app.js).
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import { updateMeSchema } from './user.validation.js';
import * as userService from './user.service.js';

const router = Router();

router.get(
  '/me',
  asyncHandler(async (req, res) => {
    res.json({ user: await userService.getById(req.user.id) });
  }),
);

router.patch(
  '/me',
  validate({ body: updateMeSchema }),
  asyncHandler(async (req, res) => {
    res.json({ user: await userService.updateSettings(req.user.id, req.body) });
  }),
);

export default router;
