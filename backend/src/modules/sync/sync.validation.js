import { z } from 'zod';

// `since` is an ISO-8601 timestamp the client received as `serverTime` from its
// previous sync. Omit it for a full initial sync.
export const syncQuerySchema = z.object({
  since: z
    .string()
    .datetime({ offset: true, message: 'since must be an ISO-8601 timestamp' })
    .optional(),
});
