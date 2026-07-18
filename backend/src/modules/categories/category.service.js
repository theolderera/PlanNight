// -----------------------------------------------------------------------------
// Category CRUD. Every query is scoped by user_id so one user can never read or
// mutate another user's data. Deletes are soft (set deleted_at) so the change
// propagates through delta sync to offline clients.
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { buildUpdateSet } from '../../common/sql.js';
import { ApiError } from '../../utils/ApiError.js';
import { serializeCategory } from './category.serializer.js';

export async function list(userId) {
  const { rows } = await query(
    `SELECT * FROM categories
     WHERE user_id = $1 AND deleted_at IS NULL
     ORDER BY lower(name)`,
    [userId],
  );
  return rows.map(serializeCategory);
}

export async function create(userId, { id, name, color }) {
  try {
    // Optional client-provided id (offline-first). A replayed create with the
    // same id is idempotent: return the existing row instead of erroring.
    const { rows } = await query(
      `INSERT INTO categories (id, user_id, name, color)
       VALUES (COALESCE($1::uuid, gen_random_uuid()), $2, $3, COALESCE($4, '#6C63FF'))
       ON CONFLICT (id) DO NOTHING
       RETURNING *`,
      [id ?? null, userId, name, color ?? null],
    );
    if (rows.length === 0) {
      const existing = await query(
        'SELECT * FROM categories WHERE id = $1 AND user_id = $2',
        [id, userId],
      );
      if (existing.rows.length === 0) throw ApiError.notFound('Category not found');
      return serializeCategory(existing.rows[0]);
    }
    return serializeCategory(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      throw ApiError.conflict('A category with that name already exists.', { code: 'CATEGORY_EXISTS' });
    }
    throw err;
  }
}

const UPDATABLE = { name: 'name', color: 'color' };

export async function update(userId, id, patch) {
  const { setClause, values, nextIndex } = buildUpdateSet(UPDATABLE, patch);
  values.push(id, userId);
  try {
    const { rows } = await query(
      `UPDATE categories SET ${setClause}
       WHERE id = $${nextIndex} AND user_id = $${nextIndex + 1} AND deleted_at IS NULL
       RETURNING *`,
      values,
    );
    if (rows.length === 0) throw ApiError.notFound('Category not found');
    return serializeCategory(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      throw ApiError.conflict('A category with that name already exists.', { code: 'CATEGORY_EXISTS' });
    }
    throw err;
  }
}

export async function remove(userId, id) {
  // Soft delete. Tasks referencing this category keep working: the FK is
  // ON DELETE SET NULL, but since we soft-delete we instead leave the reference
  // and simply stop returning the category. (The client treats a missing
  // category as "uncategorised".)
  const { rows } = await query(
    `UPDATE categories SET deleted_at = now()
     WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [id, userId],
  );
  if (rows.length === 0) throw ApiError.notFound('Category not found');
}
