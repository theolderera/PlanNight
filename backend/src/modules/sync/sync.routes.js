// -----------------------------------------------------------------------------
// Sync route (requires auth):
//   GET /sync?since=<ISO timestamp>   -> changes since `since` (or full snapshot)
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import { syncQuerySchema } from './sync.validation.js';
import * as service from './sync.service.js';

const router = Router();

router.get(
  '/',
  validate({ query: syncQuerySchema }),
  asyncHandler(async (req, res) => {
    res.json(await service.pull(req.user.id, req.validatedQuery.since));
  }),
);

export default router;
