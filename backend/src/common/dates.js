// -----------------------------------------------------------------------------
// Calendar-date helpers that operate on 'YYYY-MM-DD' strings, deliberately
// avoiding local-timezone surprises. All arithmetic is done in UTC so adding a
// day never slips due to DST.
// -----------------------------------------------------------------------------

/** Parse 'YYYY-MM-DD' to a UTC Date at midnight. */
export function parseDate(str) {
  const [y, m, d] = str.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

/** Format a UTC Date back to 'YYYY-MM-DD'. */
export function formatDate(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/** Add (or subtract) whole days to a 'YYYY-MM-DD' string. */
export function addDays(str, n) {
  const date = parseDate(str);
  date.setUTCDate(date.getUTCDate() + n);
  return formatDate(date);
}

/** Inclusive list of date strings from `from` to `to`. */
export function eachDay(from, to) {
  const out = [];
  let cursor = from;
  while (cursor <= to) {
    out.push(cursor);
    cursor = addDays(cursor, 1);
  }
  return out;
}

/**
 * "Today" as a 'YYYY-MM-DD' string in the given IANA timezone. This is what the
 * streak logic uses so a user's day rolls over at their local midnight, not the
 * server's.
 */
export function todayInTimezone(timeZone) {
  try {
    // en-CA formats as YYYY-MM-DD, which is exactly what we want.
    return new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(new Date());
  } catch {
    // Unknown timezone -> fall back to UTC.
    return formatDate(new Date());
  }
}
