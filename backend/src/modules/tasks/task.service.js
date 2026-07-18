// -----------------------------------------------------------------------------
// Task logic: CRUD, day/range listing with filters, status changes, reschedule.
// Everything is scoped by user_id. Deletes are soft (deleted_at) for sync.
// -----------------------------------------------------------------------------
import { query, withTransaction } from '../../config/db.js';
import { buildUpdateSet } from '../../common/sql.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeTask } from './task.serializer.js';

// Guard: if a categoryId is supplied it must belong to this user and be live.
async function assertCategoryOwned(userId, categoryId, client = { query }) {
  if (!categoryId) return;
  const { rows } = await client.query(
    'SELECT 1 FROM categories WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
    [categoryId, userId],
  );
  if (rows.length === 0) {
    throw ApiError.badRequest('Category does not exist.', { code: 'CATEGORY_NOT_FOUND' });
  }
}

/**
 * List tasks for a single day (`date`) or an inclusive range (`from`..`to`),
 * with optional category/priority/status filters. Ordered chronologically:
 * timed tasks first by time, then untimed by manual sort order.
 */
export async function list(userId, q) {
  const conditions = ['user_id = $1', 'deleted_at IS NULL'];
  const values = [userId];
  let i = 2;

  if (q.date) {
    conditions.push(`plan_date = $${i++}`);
    values.push(q.date);
  } else {
    conditions.push(`plan_date BETWEEN $${i++} AND $${i++}`);
    values.push(q.from, q.to);
  }
  if (q.categoryId) { conditions.push(`category_id = $${i++}`); values.push(q.categoryId); }
  if (q.priority) { conditions.push(`priority = $${i++}`); values.push(q.priority); }
  if (q.status) { conditions.push(`status = $${i++}`); values.push(q.status); }

  const { rows } = await query(
    `SELECT * FROM tasks
     WHERE ${conditions.join(' AND ')}
     ORDER BY plan_date,
              start_time ASC NULLS LAST,
              sort_order ASC,
              created_at ASC`,
    values,
  );
  return rows.map(serializeTask);
}

export async function getById(userId, id) {
  const { rows } = await query(
    'SELECT * FROM tasks WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
    [id, userId],
  );
  if (rows.length === 0) throw ApiError.notFound('Task not found');
  return serializeTask(rows[0]);
}

export async function create(userId, data) {
  await assertCategoryOwned(userId, data.categoryId);
  // Accept an optional client-provided id so offline-first clients can generate
  // the UUID locally and keep the same id after syncing. If the client replays a
  // create it already made (e.g. flaky network), we treat the duplicate id as an
  // idempotent success and return the existing row rather than erroring.
  const { rows } = await query(
    `INSERT INTO tasks
       (id, user_id, category_id, title, notes, priority,
        plan_date, start_time, duration_minutes, reminder_lead_minutes, sort_order)
     VALUES (COALESCE($1::uuid, gen_random_uuid()), $2, $3, $4, $5, COALESCE($6, 'medium'),
             $7, $8, $9, $10, COALESCE($11, 0))
     ON CONFLICT (id) DO NOTHING
     RETURNING *`,
    [
      data.id ?? null,
      userId,
      data.categoryId ?? null,
      data.title,
      data.notes ?? null,
      data.priority ?? null,
      data.planDate,
      data.startTime ?? null,
      data.durationMinutes ?? null,
      data.reminderLeadMinutes ?? null,
      data.sortOrder ?? null,
    ],
  );
  // ON CONFLICT DO NOTHING returns no row when the id already existed; fetch it,
  // ensuring it belongs to this user (never leak another user's row).
  if (rows.length === 0) {
    return getById(userId, data.id);
  }
  return serializeTask(rows[0]);
}

// Maps camelCase patch keys to columns for a dynamic UPDATE.
const UPDATABLE = {
  title: 'title',
  notes: 'notes',
  categoryId: 'category_id',
  priority: 'priority',
  planDate: 'plan_date',
  startTime: 'start_time',
  durationMinutes: 'duration_minutes',
  reminderLeadMinutes: 'reminder_lead_minutes',
  sortOrder: 'sort_order',
};

export async function update(userId, id, patch) {
  if (patch.categoryId) await assertCategoryOwned(userId, patch.categoryId);

  const { setClause, values, nextIndex } = buildUpdateSet(UPDATABLE, patch);
  values.push(id, userId);
  const { rows } = await query(
    `UPDATE tasks SET ${setClause}
     WHERE id = $${nextIndex} AND user_id = $${nextIndex + 1} AND deleted_at IS NULL
     RETURNING *`,
    values,
  );
  if (rows.length === 0) throw ApiError.notFound('Task not found');
  return serializeTask(rows[0]);
}

/**
 * Set status to planned/completed/skipped. Keeps completed_at consistent with
 * the CHECK constraint (set on complete, cleared otherwise).
 */
export async function setStatus(userId, id, status) {
  const completedAtExpr = status === 'completed' ? 'now()' : 'NULL';
  const { rows } = await query(
    `UPDATE tasks
       SET status = $1, completed_at = ${completedAtExpr}
     WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL
     RETURNING *`,
    [status, id, userId],
  );
  if (rows.length === 0) throw ApiError.notFound('Task not found');
  return serializeTask(rows[0]);
}

export async function remove(userId, id) {
  const { rows } = await query(
    `UPDATE tasks SET deleted_at = now()
     WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [id, userId],
  );
  if (rows.length === 0) throw ApiError.notFound('Task not found');
}

/**
 * Move a task to another day: mark the original as 'rescheduled' (kept for
 * history) and create a fresh 'planned' copy on the target date. Done in one
 * transaction so we never end up with only half the change.
 * @returns {{ original: object, moved: object }}
 */
export async function reschedule(userId, id, targetDate) {
  return withTransaction(async (client) => {
    const { rows } = await client.query(
      'SELECT * FROM tasks WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [id, userId],
    );
    if (rows.length === 0) throw ApiError.notFound('Task not found');
    const src = rows[0];

    if (targetDate === serializeTask(src).planDate) {
      throw ApiError.badRequest('Task is already scheduled on that date.', { code: 'SAME_DATE' });
    }

    // Mark the original as rescheduled (leaves a breadcrumb in history).
    const { rows: originalRows } = await client.query(
      `UPDATE tasks SET status = 'rescheduled', completed_at = NULL, rescheduled_to_date = $1
       WHERE id = $2 RETURNING *`,
      [targetDate, id],
    );

    // Create a fresh copy on the new day (not tied to the template, so the
    // unique template/day guard can't collide).
    const { rows: movedRows } = await client.query(
      `INSERT INTO tasks
         (user_id, category_id, title, notes, priority,
          plan_date, start_time, duration_minutes, reminder_lead_minutes, sort_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        userId, src.category_id, src.title, src.notes, src.priority,
        targetDate, src.start_time, src.duration_minutes, src.reminder_lead_minutes, src.sort_order,
      ],
    );

    return { original: serializeTask(originalRows[0]), moved: serializeTask(movedRows[0]) };
  });
}
