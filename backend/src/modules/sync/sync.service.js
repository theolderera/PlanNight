// -----------------------------------------------------------------------------
// Delta sync (server -> client pull).
//
// The client stores the `serverTime` returned by its last sync and passes it
// back as `since`. We return every row (categories, tasks, templates) whose
// updated_at is newer than `since`, INCLUDING soft-deleted rows, so the client
// can mirror deletions locally. Without `since` it's a full initial snapshot.
//
// Offline writes: the mobile app queues its own create/update/delete calls while
// offline and replays them through the normal REST endpoints on reconnect
// (newest replay wins — last-write-wins). This pull endpoint then refreshes the
// local cache. See the README "Offline & sync" section.
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { serializeCategory } from '../categories/category.serializer.js';
import { serializeTask } from '../tasks/task.serializer.js';
import { serializeTemplate } from '../recurring/recurring.serializer.js';
import { serializeUser } from '../users/user.serializer.js';

// Selects rows changed since `since` (or all rows when `since` is null),
// including soft-deleted ones. `since` is compared as a timestamptz.
async function changedRows(table, userId, since) {
  const { rows } = await query(
    `SELECT * FROM ${table}
     WHERE user_id = $1 AND ($2::timestamptz IS NULL OR updated_at > $2::timestamptz)
     ORDER BY updated_at ASC`,
    [userId, since ?? null],
  );
  return rows;
}

export async function pull(userId, since) {
  // Capture a single authoritative server timestamp for the client to reuse as
  // the next `since`. Taken from the DB clock to avoid app-server skew.
  const { rows: nowRows } = await query('SELECT now() AS server_time');
  const serverTime = nowRows[0].server_time;

  const [categories, tasks, templates, userRows] = await Promise.all([
    changedRows('categories', userId, since),
    changedRows('tasks', userId, since),
    changedRows('recurring_task_templates', userId, since),
    // The user's own settings row (single row; include when changed).
    query(
      `SELECT * FROM users
       WHERE id = $1 AND ($2::timestamptz IS NULL OR updated_at > $2::timestamptz)`,
      [userId, since ?? null],
    ).then((r) => r.rows),
  ]);

  return {
    serverTime,
    user: userRows[0] ? serializeUser(userRows[0]) : null,
    categories: categories.map(serializeCategory),
    tasks: tasks.map(serializeTask),
    templates: templates.map(serializeTemplate),
  };
}
