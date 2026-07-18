import { z } from 'zod';
import { dateString, timeString, uuid } from '../../common/schemas.js';

const priority = z.enum(['high', 'medium', 'low']);

export const createTaskSchema = z.object({
  // Optional client-generated UUID for offline-first id stability.
  id: uuid.optional(),
  title: z.string().trim().min(1, 'Title is required').max(200),
  notes: z.string().max(2000).optional(),
  categoryId: uuid.nullable().optional(),
  priority: priority.optional(), // defaults to 'medium' in DB
  planDate: dateString,
  startTime: timeString.nullable().optional(),
  durationMinutes: z.number().int().positive().max(1440).nullable().optional(),
  reminderLeadMinutes: z.number().int().min(0).max(1440).nullable().optional(),
  sortOrder: z.number().int().optional(),
});

// PATCH — every field optional, at least one required.
export const updateTaskSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    notes: z.string().max(2000).nullable().optional(),
    categoryId: uuid.nullable().optional(),
    priority: priority.optional(),
    planDate: dateString.optional(),
    startTime: timeString.nullable().optional(),
    durationMinutes: z.number().int().positive().max(1440).nullable().optional(),
    reminderLeadMinutes: z.number().int().min(0).max(1440).nullable().optional(),
    sortOrder: z.number().int().optional(),
  })
  .refine((o) => Object.keys(o).length > 0, { message: 'Provide at least one field to update.' });

// Marking done / skipped / back to planned.
export const setStatusSchema = z.object({
  status: z.enum(['planned', 'completed', 'skipped']),
});

// Move a task to another day.
export const rescheduleSchema = z.object({
  date: dateString,
});

// Query filters for GET /tasks. Either `date` (single day) or `from`+`to` (range).
export const listTasksQuerySchema = z
  .object({
    date: dateString.optional(),
    from: dateString.optional(),
    to: dateString.optional(),
    categoryId: uuid.optional(),
    priority: priority.optional(),
    status: z.enum(['planned', 'completed', 'skipped', 'rescheduled']).optional(),
  })
  .refine((q) => q.date || (q.from && q.to), {
    message: 'Provide either `date`, or both `from` and `to`.',
  })
  .refine((q) => !(q.from && q.to) || q.from <= q.to, {
    message: '`from` must be on or before `to`.',
  });

export const idParamSchema = z.object({ id: uuid });
