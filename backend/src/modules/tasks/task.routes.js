// -----------------------------------------------------------------------------
// Task routes (all require auth):
//   GET    /tasks?date=YYYY-MM-DD            single day (Today view)
//   GET    /tasks?from=...&to=...            range (History/Calendar)
//          optional filters: &categoryId= &priority= &status=
//   GET    /tasks/:id
//   POST   /tasks
//   PATCH  /tasks/:id
//   DELETE /tasks/:id
//   POST   /tasks/:id/status      { status }
//   POST   /tasks/:id/reschedule  { date }
// -----------------------------------------------------------------------------
import { Router } from 'express';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { validate } from '../../middleware/validate.js';
import * as service from './task.service.js';
import {
  createTaskSchema,
  updateTaskSchema,
  setStatusSchema,
  rescheduleSchema,
  listTasksQuerySchema,
  idParamSchema,
} from './task.validation.js';

const router = Router();

router.get(
  '/',
  validate({ query: listTasksQuerySchema }),
  asyncHandler(async (req, res) => {
    res.json({ tasks: await service.list(req.user.id, req.validatedQuery) });
  }),
);

router.post(
  '/',
  validate({ body: createTaskSchema }),
  asyncHandler(async (req, res) => {
    res.status(201).json({ task: await service.create(req.user.id, req.body) });
  }),
);

router.get(
  '/:id',
  validate({ params: idParamSchema }),
  asyncHandler(async (req, res) => {
    res.json({ task: await service.getById(req.user.id, req.params.id) });
  }),
);

router.patch(
  '/:id',
  validate({ params: idParamSchema, body: updateTaskSchema }),
  asyncHandler(async (req, res) => {
    res.json({ task: await service.update(req.user.id, req.params.id, req.body) });
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

router.post(
  '/:id/status',
  validate({ params: idParamSchema, body: setStatusSchema }),
  asyncHandler(async (req, res) => {
    res.json({ task: await service.setStatus(req.user.id, req.params.id, req.body.status) });
  }),
);

router.post(
  '/:id/reschedule',
  validate({ params: idParamSchema, body: rescheduleSchema }),
  asyncHandler(async (req, res) => {
    res.json(await service.reschedule(req.user.id, req.params.id, req.body.date));
  }),
);

export default router;
