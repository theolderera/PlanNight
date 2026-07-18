import { z } from 'zod';
import { timeString } from '../../common/schemas.js';

/** UI languages the app ships translations for. */
export const supportedLanguages = ['en', 'ru', 'tg'];

// All fields optional — this is a PATCH. At least one must be present.
export const updateMeSchema = z
  .object({
    timezone: z.string().min(1).max(64).optional(),
    language: z.enum(supportedLanguages).optional(),
    theme: z.enum(['light', 'dark', 'system']).optional(),
    streakThresholdPct: z.number().int().min(1).max(100).optional(),
    notificationsEnabled: z.boolean().optional(),
    reminderLeadMinutes: z.number().int().min(0).max(1440).optional(),
    eveningReminderEnabled: z.boolean().optional(),
    eveningReminderTime: timeString.optional(),
  })
  .refine((obj) => Object.keys(obj).length > 0, {
    message: 'Provide at least one field to update.',
  });
