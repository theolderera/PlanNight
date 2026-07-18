function toDateString(value) {
  if (value == null) return null;
  if (value instanceof Date) {
    const y = value.getFullYear();
    const m = String(value.getMonth() + 1).padStart(2, '0');
    const d = String(value.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
  return String(value).slice(0, 10);
}

export function serializeTemplate(row) {
  return {
    id: row.id,
    title: row.title,
    notes: row.notes,
    categoryId: row.category_id,
    priority: row.priority,
    startTime: row.start_time ? String(row.start_time).slice(0, 5) : null,
    durationMinutes: row.duration_minutes,
    reminderLeadMinutes: row.reminder_lead_minutes,
    recurrenceType: row.recurrence_type,
    daysOfWeek: row.days_of_week ?? [],
    startDate: toDateString(row.start_date),
    endDate: toDateString(row.end_date),
    active: row.active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at,
  };
}
