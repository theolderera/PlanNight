// -----------------------------------------------------------------------------
// Password hashing helpers. We use bcryptjs (pure JS) so there is no native
// build step in Docker/alpine. The work factor comes from BCRYPT_ROUNDS.
// -----------------------------------------------------------------------------
import bcrypt from 'bcryptjs';
import { env } from '../config/env.js';

/** Hash a plaintext password for storage. */
export function hashPassword(plain) {
  return bcrypt.hash(plain, env.BCRYPT_ROUNDS);
}

/** Compare a plaintext password against a stored hash. */
export function verifyPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}
