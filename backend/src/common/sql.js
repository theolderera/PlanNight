// -----------------------------------------------------------------------------
// Helpers for building parameterised SQL.
// -----------------------------------------------------------------------------
import { ApiError } from '../utils/ApiError.js';

/**
 * Build the `SET` clause of a dynamic UPDATE from a PATCH body.
 *
 * Only keys present in `columnMap` are ever used, and column names come from
 * that map — never from user input — so there is nothing to inject. Values are
 * returned separately as $1, $2, ... placeholders.
 *
 * A patch with no recognised fields would otherwise produce `UPDATE t SET  WHERE
 * ...`, a syntax error surfacing as a confusing 500. We reject it as a 400
 * instead. (Route validation should already require one field; this is the
 * belt-and-braces guard for any caller that skips it.)
 *
 * @param {Record<string,string>} columnMap  apiKey -> column_name
 * @param {Record<string,any>} patch         the request body
 * @param {number} [startIndex=1]            first placeholder number to use
 * @returns {{ setClause: string, values: any[], nextIndex: number }}
 */
export function buildUpdateSet(columnMap, patch, startIndex = 1) {
  const fragments = [];
  const values = [];
  let i = startIndex;

  for (const [apiKey, column] of Object.entries(columnMap)) {
    if (patch[apiKey] !== undefined) {
      fragments.push(`${column} = $${i++}`);
      values.push(patch[apiKey]);
    }
  }

  if (fragments.length === 0) {
    throw ApiError.badRequest('Provide at least one field to update.', {
      code: 'EMPTY_PATCH',
    });
  }

  return { setClause: fragments.join(', '), values, nextIndex: i };
}
