import { z } from 'zod';
import { dateString, timeString, uuid } from '../../common/schemas.js';

const priority = z.enum(['high', 'medium', 'low']);
const recurrenceType = z.enum(['daily', 'weekly', 'custom']);

// Days of week 0 (Sun)..6 (Sat), unique. Unlike the shared `daysOfWeek` schema
// this permits an EMPTY array: a 'daily' template legitimately carries no days,
// and the offline client always serialises the field (sends `[]`, not omitted).
// The non-empty requirement for weekly/custom is enforced by the superRefine
// below — putting `.min(1)` here would reject every daily template with a 400.
const daysOfWeekArray = z
  .array(z.number().int().min(0).max(6))
  .refine((arr) => new Set(arr).size === arr.length, 'Days of week must be unique');

// For 'weekly'/'custom' a non-empty daysOfWeek is required; for 'daily' it is
// ignored (and defaulted to []).
const requireDaysForNonDaily = (obj, ctx) => {
  if (obj.recurrenceType && obj.recurrenceType !== 'daily') {
    if (!obj.daysOfWeek || obj.daysOfWeek.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['daysOfWeek'],
        message: 'daysOfWeek is required for weekly/custom recurrence.',
      });
    }
  }
};

export const createTemplateSchema = z
  .object({
    id: uuid.optional(), // optional client-generated id (offline-first)
    title: z.string().trim().min(1, 'Title is required').max(200),
    // Nullable — the offline client serialises `notes: null` for note-less
    // templates; rejecting that null blocks them from ever syncing.
    notes: z.string().max(2000).nullable().optional(),
    categoryId: uuid.nullable().optional(),
    priority: priority.optional(),
    startTime: timeString,
    durationMinutes: z.number().int().positive().max(1440).nullable().optional(),
    reminderLeadMinutes: z.number().int().min(0).max(1440).nullable().optional(),
    recurrenceType,
    daysOfWeek: daysOfWeekArray.optional(),
    startDate: dateString.optional(),
    endDate: dateString.nullable().optional(),
    active: z.boolean().optional(),
  })
  .superRefine(requireDaysForNonDaily);

export const updateTemplateSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    notes: z.string().max(2000).nullable().optional(),
    categoryId: uuid.nullable().optional(),
    priority: priority.optional(),
    startTime: timeString.optional(),
    durationMinutes: z.number().int().positive().max(1440).nullable().optional(),
    reminderLeadMinutes: z.number().int().min(0).max(1440).nullable().optional(),
    recurrenceType: recurrenceType.optional(),
    daysOfWeek: daysOfWeekArray.optional(),
    startDate: dateString.optional(),
    endDate: dateString.nullable().optional(),
    active: z.boolean().optional(),
  })
  .refine((o) => Object.keys(o).length > 0, { message: 'Provide at least one field to update.' })
  .superRefine(requireDaysForNonDaily);

// POST /planning/generate — materialise templates into task rows for a day.
export const generateSchema = z.object({
  date: dateString,
});

export const idParamSchema = z.object({ id: uuid });
