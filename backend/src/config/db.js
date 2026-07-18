// -----------------------------------------------------------------------------
// PostgreSQL connection pool.
//
// We expose two things:
//   - `query(text, params)`  : run a one-off parameterised query.
//   - `withTransaction(fn)`  : run several queries atomically. `fn` receives a
//                              dedicated client; if it throws, we ROLLBACK.
//
// Always pass values as parameters ($1, $2, ...) — never string-concatenate
// user input into SQL. That is what prevents SQL injection.
// -----------------------------------------------------------------------------
import pg from 'pg';
import { env } from './env.js';

const { Pool } = pg;

// Prefer a single DATABASE_URL when provided (common on managed hosts),
// otherwise assemble from the individual DB_* parts.
const poolConfig = env.DATABASE_URL
  ? { connectionString: env.DATABASE_URL }
  : {
      host: env.DB_HOST,
      port: env.DB_PORT,
      user: env.DB_USER,
      password: env.DB_PASSWORD,
      database: env.DB_NAME,
    };

if (env.DB_SSL) {
  // `rejectUnauthorized: false` is common for managed Postgres providers that
  // present a self-signed chain. Tighten this if your provider gives you a CA.
  poolConfig.ssl = { rejectUnauthorized: false };
}

export const pool = new Pool(poolConfig);

// A crashed idle client should not take the whole process down silently.
pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
});

/**
 * Run a single parameterised query against the pool.
 * @param {string} text  SQL with $1, $2 ... placeholders.
 * @param {any[]} [params]
 */
export function query(text, params) {
  return pool.query(text, params);
}

/**
 * Run `fn` inside a single transaction. Commits on success, rolls back on error.
 * @template T
 * @param {(client: import('pg').PoolClient) => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function withTransaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/** Gracefully close the pool (used on shutdown). */
export function closePool() {
  return pool.end();
}
