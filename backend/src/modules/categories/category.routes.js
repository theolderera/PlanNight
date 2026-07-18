// -----------------------------------------------------------------------------
// Category routes (all require auth):
//   GET    /categories
//   POST   /categories
//   PATCH  /categories/:id
//   DELETE /categories/:id
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import * as service from './category.service.js';
import {
  createCategorySchema,
  updateCategorySchema,
  idParamSchema,
} from './category.validation.js';

const router = Router();

router.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json({ categories: await service.list(req.user.id) });
  }),
);

router.post(
  '/',
  validate({ body: createCategorySchema }),
  asyncHandler(async (req, res) => {
    res.status(201).json({ category: await service.create(req.user.id, req.body) });
  }),
);

router.patch(
  '/:id',
  validate({ params: idParamSchema, body: updateCategorySchema }),
  asyncHandler(async (req, res) => {
    res.json({ category: await service.update(req.user.id, req.params.id, req.body) });
  }),
);

router.delete(
  '/:id',
  validate({ params: idParamSchema }),
  asyncHandler(async (req, res) => {
    await service.remove(req.user.id, req.params.id);
    res.status(204).send();
  }),
);

export default router;
