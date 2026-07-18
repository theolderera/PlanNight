// -----------------------------------------------------------------------------
// Small reusable zod schemas shared across modules (dates, times, ids).
// -----------------------------------------------------------------------------
import { z } from 'zod';

// 'YYYY-MM-DD' calendar date, validated to be a real date (rejects 2026-13-40).
export const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD')
  .refine((s) => {
    const [y, m, d] = s.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d));
    return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
  }, 'Not a valid calendar date');

// 'HH:MM' or 'HH:MM:SS' wall-clock time.
export const timeString = z
  .string()
  .regex(/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/, 'Time must be HH:MM (24h)');

export const uuid = z.string().uuid('Invalid id');

// Days of week: 0 (Sun) .. 6 (Sat), unique, non-empty.
export const daysOfWeek = z
  .array(z.number().int().min(0).max(6))
  .min(1, 'Provide at least one day of week')
  .refine((arr) => new Set(arr).size === arr.length, 'Days of week must be unique');
