// -----------------------------------------------------------------------------
// Process entry point: create the app, start listening, and shut down cleanly.
// -----------------------------------------------------------------------------
import { createApp } from './app.js';
import { env } from './config/env.js';
import { pool, closePool } from './config/db.js';

const app = createApp();

// Verify the DB is reachable on boot so we fail fast with a clear message rather
// than erroring on the first request.
try {
  await pool.query('SELECT 1');
  console.log('✅ Connected to PostgreSQL');
} catch (err) {
  console.error('❌ Could not connect to PostgreSQL:', err.message);
  process.exit(1);
}

const server = app.listen(env.PORT, () => {
  console.log(`🚀 PlanNight API listening on http://localhost:${env.PORT} (${env.NODE_ENV})`);
});

// Graceful shutdown: stop accepting connections, then close the DB pool.
async function shutdown(signal) {
  console.log(`\n${signal} received — shutting down...`);
  server.close(async () => {
    await closePool();
    console.log('Closed HTTP server and DB pool. Bye 👋');
    process.exit(0);
  });
  // Force-exit if something hangs.
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
