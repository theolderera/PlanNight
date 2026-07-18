// Formats a DATE column (which node-postgres may hand back as a Date object)
// into a plain 'YYYY-MM-DD' string, since these are timezone-less calendar days.
function toDateString(value) {
  if (value == null) return null;
  if (value instanceof Date) {
    const y = value.getFullYear();
    const m = String(value.getMonth() + 1).padStart(2, '0');
    const d = String(value.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
  // Already a string like '2026-07-08' (or with time) — keep the date part.
  return String(value).slice(0, 10);
}

export function serializeTask(row) {
  return {
    id: row.id,
    title: row.title,
    notes: row.notes,
    categoryId: row.category_id,
    templateId: row.template_id,
    priority: row.priority,
    planDate: toDateString(row.plan_date),
    startTime: row.start_time ? String(row.start_time).slice(0, 5) : null, // HH:MM
    durationMinutes: row.duration_minutes,
    reminderLeadMinutes: row.reminder_lead_minutes,
    status: row.status,
    completedAt: row.completed_at,
    rescheduledToDate: toDateString(row.rescheduled_to_date),
    sortOrder: row.sort_order,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at,
  };
}
