// -----------------------------------------------------------------------------
// Progress statistics, computed on the fly from `tasks`.
//
// Terminology:
//   total   = tasks that count toward the day (not deleted, not rescheduled away)
//   done    = completed
//   pct     = round(done / total * 100), or 0 when total = 0
//   success = total > 0 AND pct >= user's streak_threshold_pct
// -----------------------------------------------------------------------------
import { query } from '../../config/db.js';
import { ApiError } from '../../utils/ApiError.js';
import { addDays, eachDay, todayInTimezone } from '../../common/dates.js';

function pct(done, total) {
  return total === 0 ? 0 : Math.round((done / total) * 100);
}

async function getUserStreakConfig(userId) {
  const { rows } = await query(
    'SELECT timezone, streak_threshold_pct FROM users WHERE id = $1',
    [userId],
  );
  if (rows.length === 0) throw ApiError.notFound('User not found');
  return { timezone: rows[0].timezone, threshold: rows[0].streak_threshold_pct };
}

// Shared aggregate: per-day counts for a user across [from, to].
async function dayAggregates(userId, from, to) {
  const { rows } = await query(
    `SELECT plan_date::text AS date,
            COUNT(*) FILTER (WHERE status <> 'rescheduled')      AS total,
            COUNT(*) FILTER (WHERE status = 'completed')         AS completed,
            COUNT(*) FILTER (WHERE status = 'skipped')           AS skipped,
            COUNT(*) FILTER (WHERE status = 'planned')           AS pending
     FROM tasks
     WHERE user_id = $1 AND deleted_at IS NULL
       AND plan_date BETWEEN $2 AND $3
     GROUP BY plan_date`,
    [userId, from, to],
  );
  // Map date -> numeric counts.
  const map = new Map();
  for (const r of rows) {
    map.set(r.date.slice(0, 10), {
      total: Number(r.total),
      completed: Number(r.completed),
      skipped: Number(r.skipped),
      pending: Number(r.pending),
    });
  }
  return map;
}

/** Single-day breakdown for the Today view / a history day. */
export async function daily(userId, date) {
  const { threshold } = await getUserStreakConfig(userId);
  const map = await dayAggregates(userId, date, date);
  const c = map.get(date) ?? { total: 0, completed: 0, skipped: 0, pending: 0 };
  const completionPct = pct(c.completed, c.total);
  return {
    date,
    total: c.total,
    completed: c.completed,
    skipped: c.skipped,
    pending: c.pending,
    completionPct,
    successful: c.total > 0 && completionPct >= threshold,
  };
}

/**
 * Per-day breakdown + totals across a range. Days with no tasks are included as
 * zeroes so charts have a continuous x-axis. Used by the weekly screen and the
 * monthly trend chart.
 */
export async function summary(userId, from, to) {
  const { threshold } = await getUserStreakConfig(userId);
  const map = await dayAggregates(userId, from, to);

  const days = eachDay(from, to).map((date) => {
    const c = map.get(date) ?? { total: 0, completed: 0, skipped: 0, pending: 0 };
    const completionPct = pct(c.completed, c.total);
    return {
      date,
      total: c.total,
      completed: c.completed,
      skipped: c.skipped,
      pending: c.pending,
      completionPct,
      successful: c.total > 0 && completionPct >= threshold,
    };
  });

  const totalTasks = days.reduce((s, d) => s + d.total, 0);
  const totalCompleted = days.reduce((s, d) => s + d.completed, 0);

  return {
    from,
    to,
    threshold,
    days,
    totals: {
      totalTasks,
      totalCompleted,
      completionPct: pct(totalCompleted, totalTasks),
      successfulDays: days.filter((d) => d.successful).length,
      // Days that actually had at least one task planned.
      activeDays: days.filter((d) => d.total > 0).length,
    },
  };
}

/**
 * Current and longest streaks of successful days.
 *
 * The current streak counts consecutive successful days ending today. If today
 * is not yet successful (e.g. the day is still in progress), we start counting
 * from yesterday so an unfinished day doesn't prematurely zero the streak.
 */
export async function streak(userId) {
  const { timezone, threshold } = await getUserStreakConfig(userId);
  const today = todayInTimezone(timezone);
  const windowStart = addDays(today, -365); // one-year lookback

  const map = await dayAggregates(userId, windowStart, today);
  const isSuccessful = (date) => {
    const c = map.get(date);
    return !!c && c.total > 0 && pct(c.completed, c.total) >= threshold;
  };

  // Current streak (with grace for an in-progress today).
  let current = 0;
  let cursor = isSuccessful(today) ? today : addDays(today, -1);
  while (cursor >= windowStart && isSuccessful(cursor)) {
    current += 1;
    cursor = addDays(cursor, -1);
  }

  // Longest streak across the window.
  let longest = 0;
  let run = 0;
  for (const date of eachDay(windowStart, today)) {
    if (isSuccessful(date)) {
      run += 1;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  return { current, longest, threshold, asOf: today };
}
