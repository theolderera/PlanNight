// -----------------------------------------------------------------------------
// Centralised, validated environment configuration.
//
// We load the .env file once here and validate everything with zod. If a
// required variable is missing or malformed, the process exits immediately with
// a clear message — this is far easier to debug than a `undefined` surfacing
// deep inside a request handler later on.
// -----------------------------------------------------------------------------
import 'dotenv/config';
import { z } from 'zod';

// A small helper so booleans can be provided as "true"/"false" strings in .env.
const booleanString = z
  .enum(['true', 'false'])
  .transform((value) => value === 'true');

const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  CORS_ORIGINS: z.string().default('*'),

  // Database — either a full URL or the individual parts.
  DATABASE_URL: z.string().url().optional(),
  DB_HOST: z.string().default('localhost'),
  DB_PORT: z.coerce.number().int().positive().default(5432),
  DB_USER: z.string().default('plannight'),
  DB_PASSWORD: z.string().default('plannight'),
  DB_NAME: z.string().default('plannight'),
  DB_SSL: booleanString.default('false'),

  // Auth
  JWT_ACCESS_SECRET: z.string().min(16, 'JWT_ACCESS_SECRET must be at least 16 chars'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET must be at least 16 chars'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),
  BCRYPT_ROUNDS: z.coerce.number().int().min(8).max(15).default(12),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // Flatten produces a readable { fieldErrors, formErrors } object.
  console.error('❌ Invalid environment configuration:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

if (parsed.data.JWT_ACCESS_SECRET === parsed.data.JWT_REFRESH_SECRET) {
  console.error('❌ JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be different.');
  process.exit(1);
}

// Freeze so nothing can mutate config at runtime by accident.
export const env = Object.freeze(parsed.data);

export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';
