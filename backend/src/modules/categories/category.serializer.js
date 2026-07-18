export function serializeCategory(row) {
  return {
    id: row.id,
    name: row.name,
    color: row.color,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at, // null unless soft-deleted (surfaced by sync)
  };
}
