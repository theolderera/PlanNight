import { z } from 'zod';

const hexColor = z
  .string()
  .regex(/^#[0-9A-Fa-f]{6}$/, 'Color must be a 6-digit hex value like #6C63FF');

export const createCategorySchema = z.object({
  id: z.string().uuid().optional(), // optional client-generated id (offline-first)
  name: z.string().trim().min(1, 'Name is required').max(60),
  color: hexColor.optional(), // defaults in the DB if omitted
});

export const updateCategorySchema = z
  .object({
    name: z.string().trim().min(1).max(60).optional(),
    color: hexColor.optional(),
  })
  .refine((o) => Object.keys(o).length > 0, { message: 'Provide at least one field to update.' });

export const idParamSchema = z.object({
  id: z.string().uuid('Invalid id'),
});
