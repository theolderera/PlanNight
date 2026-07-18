import { z } from 'zod';
import { dateString } from '../../common/schemas.js';

export const dailyQuerySchema = z.object({
  date: dateString,
});

// Range summary used for the weekly screen (7 days) and monthly charts (~30).
export const summaryQuerySchema = z
  .object({
    from: dateString,
    to: dateString,
  })
  .refine((q) => q.from <= q.to, { message: '`from` must be on or before `to`.' })
  .refine((q) => {
    // Guard against unbounded ranges.
    const days = (Date.parse(q.to) - Date.parse(q.from)) / 86_400_000;
    return days <= 366;
  }, { message: 'Range must not exceed 366 days.' });
