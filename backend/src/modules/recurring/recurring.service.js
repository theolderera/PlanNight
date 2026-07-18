// -----------------------------------------------------------------------------
// Recurring task templates: CRUD + the "generate a day" expansion that turns
// matching templates into concrete `tasks` rows.
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { buildUpdateSet } from '../../common/sql.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeTemplate } from './recurring.serializer.js';
import { serializeTask } from '../tasks/task.serializer.js';

async function assertCategoryOwned(userId, categoryId) {
  if (!categoryId) return;
  const { rows } = await query(
    'SELECT 1 FROM categories WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
    [categoryId, userId],
  );
  if (rows.length === 0) {
    throw ApiError.badRequest('Category does not exist.', { code: 'CATEGORY_NOT_FOUND' });
  }
}

export async function list(userId) {
  const { rows } = await query(
    `SELECT * FROM recurring_task_templates
     WHERE user_id = $1 AND deleted_at IS NULL
     ORDER BY start_time, lower(title)`,
    [userId],
  );
  return rows.map(serializeTemplate);
}

export async function create(userId, data) {
  await assertCategoryOwned(userId, data.categoryId);
  const days = data.recurrenceType === 'daily' ? [] : (data.daysOfWeek ?? []);
  // Optional client-provided id (offline-first); replayed create is idempotent.
  const { rows } = await query(
    `INSERT INTO recurring_task_templates
       (id, user_id, category_id, title, notes, priority, start_time, duration_minutes,
        reminder_lead_minutes, recurrence_type, days_of_week, start_date, end_date, active)
     VALUES (COALESCE($1::uuid, gen_random_uuid()), $2, $3, $4, $5, COALESCE($6,'medium'), $7, $8, $9, $10, $11,
             COALESCE($12, CURRENT_DATE), $13, COALESCE($14, TRUE))
     ON CONFLICT (id) DO NOTHING
     RETURNING *`,
    [
      data.id ?? null,
      userId, data.categoryId ?? null, data.title, data.notes ?? null, data.priority ?? null,
      data.startTime, data.durationMinutes ?? null, data.reminderLeadMinutes ?? null,
      data.recurrenceType, days, data.startDate ?? null, data.endDate ?? null,
      data.active ?? null,
    ],
  );
  if (rows.length === 0) {
    const existing = await query(
      'SELECT * FROM recurring_task_templates WHERE id = $1 AND user_id = $2',
      [data.id, userId],
    );
    if (existing.rows.length === 0) throw ApiError.notFound('Template not found');
    return serializeTemplate(existing.rows[0]);
  }
  return serializeTemplate(rows[0]);
}

const UPDATABLE = {
  title: 'title',
  notes: 'notes',
  categoryId: 'category_id',
  priority: 'priority',
  startTime: 'start_time',
  durationMinutes: 'duration_minutes',
  reminderLeadMinutes: 'reminder_lead_minutes',
  recurrenceType: 'recurrence_type',
  daysOfWeek: 'days_of_week',
  startDate: 'start_date',
  endDate: 'end_date',
  active: 'active',
};

export async function update(userId, id, patch) {
  if (patch.categoryId) await assertCategoryOwned(userId, patch.categoryId);

  // If switching to daily, force days_of_week empty to satisfy the DB constraint.
  if (patch.recurrenceType === 'daily') patch = { ...patch, daysOfWeek: [] };

  const { setClause, values, nextIndex } = buildUpdateSet(UPDATABLE, patch);
  values.push(id, userId);
  const { rows } = await query(
    `UPDATE recurring_task_templates SET ${setClause}
     WHERE id = $${nextIndex} AND user_id = $${nextIndex + 1} AND deleted_at IS NULL
     RETURNING *`,
    values,
  );
  if (rows.length === 0) throw ApiError.notFound('Template not found');
  return serializeTemplate(rows[0]);
}

export async function remove(userId, id) {
  // Soft-delete the template. Already-generated task rows are left untouched so
  // history/stats stay intact; only future generation stops.
  const { rows } = await query(
    `UPDATE recurring_task_templates SET deleted_at = now()
     WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [id, userId],
  );
  if (rows.length === 0) throw ApiError.notFound('Template not found');
}

/**
 * Expand all matching active templates into concrete tasks for `date`.
 * Idempotent: a template already generated for that date is skipped (ON CONFLICT
 * against the partial unique index), so calling this repeatedly is safe.
 * @returns {object[]} the newly created task rows (empty if nothing to add).
 */
export async function generateForDate(userId, date) {
  // JS day-of-week (0=Sun..6=Sat) for the target calendar date.
  const [y, m, d] = date.split('-').map(Number);
  const dow = new Date(Date.UTC(y, m - 1, d)).getUTCDay();

  const { rows } = await query(
    `INSERT INTO tasks
       (user_id, category_id, template_id, title, notes, priority,
        plan_date, start_time, duration_minutes, reminder_lead_minutes)
     SELECT t.user_id, t.category_id, t.id, t.title, t.notes, t.priority,
            $2::date, t.start_time, t.duration_minutes, t.reminder_lead_minutes
     FROM recurring_task_templates t
     WHERE t.user_id = $1
       AND t.deleted_at IS NULL
       AND t.active = TRUE
       AND t.start_date <= $2::date
       AND (t.end_date IS NULL OR t.end_date >= $2::date)
       AND (t.recurrence_type = 'daily' OR $3 = ANY(t.days_of_week))
     ON CONFLICT (user_id, template_id, plan_date)
       WHERE template_id IS NOT NULL AND deleted_at IS NULL
       DO NOTHING
     RETURNING *`,
    [userId, date, dow],
  );
  return rows.map(serializeTask);
}
