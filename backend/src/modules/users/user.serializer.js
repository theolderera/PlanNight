// -----------------------------------------------------------------------------
// Maps a raw `users` row to the public shape we return in API responses.
// Crucially, this NEVER includes password_hash.
// -----------------------------------------------------------------------------
export function serializeUser(row) {
  return {
    id: row.id,
    email: row.email,
    timezone: row.timezone,
    language: row.language,
    theme: row.theme,
    streakThresholdPct: row.streak_threshold_pct,
    notificationsEnabled: row.notifications_enabled,
    reminderLeadMinutes: row.reminder_lead_minutes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
