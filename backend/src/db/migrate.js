// -----------------------------------------------------------------------------
// Tiny SQL migration runner (no ORM, no magic).
//
// Every *.sql file in ./migrations is applied once, in filename order, inside a
// transaction. Applied filenames are recorded in the `schema_migrations` table
// so re-running is safe and idempotent.
//
// Usage:
//   node src/db/migrate.js up       # apply all pending migrations
//   node src/db/migrate.js status   # list applied vs pending
// -----------------------------------------------------------------------------
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from '../config/db.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = join(__dirname, 'migrations');

async function ensureMigrationsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename    TEXT PRIMARY KEY,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
}

async function getMigrationFiles() {
  const entries = await readdir(MIGRATIONS_DIR);
  return entries.filter((f) => f.endsWith('.sql')).sort(); // 001_, 002_, ...
}

async function getAppliedSet() {
  const { rows } = await pool.query('SELECT filename FROM schema_migrations');
  return new Set(rows.map((r) => r.filename));
}

async function up() {
  await ensureMigrationsTable();
  const files = await getMigrationFiles();
  const applied = await getAppliedSet();
  const pending = files.filter((f) => !applied.has(f));

  if (pending.length === 0) {
    console.log('✅ No pending migrations. Database is up to date.');
    return;
  }

  for (const filename of pending) {
    const sql = await readFile(join(MIGRATIONS_DIR, filename), 'utf8');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query(
        'INSERT INTO schema_migrations (filename) VALUES ($1)',
        [filename],
      );
      await client.query('COMMIT');
      console.log(`⬆️  Applied ${filename}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`❌ Failed to apply ${filename}:`, err.message);
      throw err;
    } finally {
      client.release();
    }
  }
  console.log(`✅ Applied ${pending.length} migration(s).`);
}

async function status() {
  await ensureMigrationsTable();
  const files = await getMigrationFiles();
  const applied = await getAppliedSet();
  console.log('Migration status:');
  for (const f of files) {
    console.log(`  ${applied.has(f) ? '✅ applied ' : '⬜ pending '} ${f}`);
  }
}

const command = process.argv[2] ?? 'up';

try {
  if (command === 'up') await up();
  else if (command === 'status') await status();
  else {
    console.error(`Unknown command "${command}". Use "up" or "status".`);
    process.exitCode = 1;
  }
} catch (err) {
  console.error(err);
  process.exitCode = 1;
} finally {
  await pool.end();
}
