import { z } from 'zod';
import { supportedLanguages } from '../users/user.validation.js';

// A permissive-but-sane password policy: long enough to matter, capped so a
// pathological input can't waste bcrypt time.
const password = z.string().min(8, 'Password must be at least 8 characters').max(128);
const email = z.string().trim().toLowerCase().email('A valid email is required');

export const registerSchema = z.object({
  email,
  password,
  // Optional at signup; the client usually sends the device's IANA timezone.
  timezone: z.string().min(1).max(64).optional(),
  // Optional at signup; the client sends the device's UI language when we ship a
  // translation for it, so the account starts in the language the user reads.
  language: z.enum(supportedLanguages).optional(),
});

export const loginSchema = z.object({
  email,
  password: z.string().min(1, 'Password is required'),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'refreshToken is required'),
});
