// -----------------------------------------------------------------------------
// Recurring template routes (all require auth):
//   GET    /recurring-templates
//   POST   /recurring-templates
//   PATCH  /recurring-templates/:id
//   DELETE /recurring-templates/:id
//
// Plus the planning generation endpoint:
//   POST   /planning/generate   { date }   -> materialise templates into tasks
//
// Both are exported so app.js can mount them under different base paths.
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import * as service from './recurring.service.js';
import {
  createTemplateSchema,
  updateTemplateSchema,
  generateSchema,
  idParamSchema,
} from './recurring.validation.js';

export const templatesRouter = Router();

templatesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json({ templates: await service.list(req.user.id) });
  }),
);

templatesRouter.post(
  '/',
  validate({ body: createTemplateSchema }),
  asyncHandler(async (req, res) => {
    res.status(201).json({ template: await service.create(req.user.id, req.body) });
  }),
);

templatesRouter.patch(
  '/:id',
  validate({ params: idParamSchema, body: updateTemplateSchema }),
  asyncHandler(async (req, res) => {
    res.json({ template: await service.update(req.user.id, req.params.id, req.body) });
  }),
);

templatesRouter.delete(
  '/:id',
  validate({ params: idParamSchema }),
  asyncHandler(async (req, res) => {
    await service.remove(req.user.id, req.params.id);
    res.status(204).send();
  }),
);

export const planningRouter = Router();

// Called by the evening-planning flow (e.g. "prepare tomorrow"). Returns the
// tasks that were newly created; an empty array means everything already existed.
planningRouter.post(
  '/generate',
  validate({ body: generateSchema }),
  asyncHandler(async (req, res) => {
    const created = await service.generateForDate(req.user.id, req.body.date);
    res.json({ created, count: created.length });
  }),
);
