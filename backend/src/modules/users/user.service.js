// -----------------------------------------------------------------------------
// User profile & settings logic.
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { buildUpdateSet } from '../../common/sql.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeUser } from './user.serializer.js';

export async function getById(userId) {
  const { rows } = await query('SELECT * FROM users WHERE id = $1', [userId]);
  if (rows.length === 0) throw ApiError.notFound('User not found');
  return serializeUser(rows[0]);
}

// Maps camelCase API fields to snake_case columns for the settings update.
const UPDATABLE_COLUMNS = {
  timezone: 'timezone',
  language: 'language',
  theme: 'theme',
  streakThresholdPct: 'streak_threshold_pct',
  notificationsEnabled: 'notifications_enabled',
  reminderLeadMinutes: 'reminder_lead_minutes',
  eveningReminderEnabled: 'evening_reminder_enabled',
  eveningReminderTime: 'evening_reminder_time',
};

export async function updateSettings(userId, patch) {
  // Build a dynamic, still-parameterised SET clause from the provided fields.
  const { setClause, values, nextIndex } = buildUpdateSet(UPDATABLE_COLUMNS, patch);

  values.push(userId); // final placeholder is the WHERE id
  const { rows } = await query(
    `UPDATE users SET ${setClause} WHERE id = $${nextIndex} RETURNING *`,
    values,
  );
  if (rows.length === 0) throw ApiError.notFound('User not found');
  return serializeUser(rows[0]);
}
