// -----------------------------------------------------------------------------
// Stats routes (all require auth):
//   GET /stats/daily?date=YYYY-MM-DD           one day's breakdown
//   GET /stats/summary?from=...&to=...         per-day breakdown + totals
//   GET /stats/streak                          current & longest streak
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import * as service from './stats.service.js';
import { dailyQuerySchema, summaryQuerySchema } from './stats.validation.js';

const router = Router();

router.get(
  '/daily',
  validate({ query: dailyQuerySchema }),
  asyncHandler(async (req, res) => {
    res.json(await service.daily(req.user.id, req.validatedQuery.date));
  }),
);

router.get(
  '/summary',
  validate({ query: summaryQuerySchema }),
  asyncHandler(async (req, res) => {
    const { from, to } = req.validatedQuery;
    res.json(await service.summary(req.user.id, from, to));
  }),
);

router.get(
  '/streak',
  asyncHandler(async (req, res) => {
    res.json(await service.streak(req.user.id));
  }),
);

export default router;
