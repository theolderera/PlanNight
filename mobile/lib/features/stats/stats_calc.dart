import '../../core/date_utils.dart';
import '../../data/models/stats.dart';
import '../../data/models/task.dart';

/// Local, offline-first computation of the progress statistics.
///
/// Mirrors the server's `stats.service.js` exactly so the numbers match whether
/// they are read from the API or computed here from the drift cache:
///   * a day's `total` excludes `rescheduled` tasks (they moved elsewhere),
///   * `completionPct = round(completed / total * 100)`, or 0 when total is 0,
///   * a day is `successful` when it has tasks and its pct meets the threshold.
///
/// Computing locally means Progress works offline and updates the instant a task
/// is checked off, instead of being a stale online snapshot.
class _DayCounts {
  int total = 0;
  int completed = 0;
  int skipped = 0;
  int pending = 0;
}

int _pct(int done, int total) => total == 0 ? 0 : (done / total * 100).round();

/// Bucket a task list into per-date counts (keyed by 'YYYY-MM-DD').
Map<String, _DayCounts> _bucket(List<Task> tasks) {
  final map = <String, _DayCounts>{};
  for (final t in tasks) {
    final c = map.putIfAbsent(Dates.iso(t.planDate), _DayCounts.new);
    if (t.status == TaskStatus.rescheduled) continue; // not counted at all
    c.total++;
    switch (t.status) {
      case TaskStatus.completed:
        c.completed++;
      case TaskStatus.skipped:
        c.skipped++;
      case TaskStatus.planned:
        c.pending++;
      case TaskStatus.rescheduled:
        break;
    }
  }
  return map;
}

DayStat _dayStat(String date, _DayCounts? c, int threshold) {
  final counts = c ?? _DayCounts();
  final pct = _pct(counts.completed, counts.total);
  return DayStat(
    date: date,
    total: counts.total,
    completed: counts.completed,
    skipped: counts.skipped,
    pending: counts.pending,
    completionPct: pct,
    successful: counts.total > 0 && pct >= threshold,
  );
}

/// Per-day breakdown + totals across [from]..[to] (inclusive, zero-filled so the
/// chart has a continuous axis). Equivalent to `GET /stats/summary`.
SummaryStat computeSummary(
  List<Task> tasks, {
  required String from,
  required String to,
  required int threshold,
}) {
  final map = _bucket(tasks);
  final days = <DayStat>[];
  var cursor = Dates.parse(from);
  final end = Dates.parse(to);
  while (!cursor.isAfter(end)) {
    final iso = Dates.iso(cursor);
    days.add(_dayStat(iso, map[iso], threshold));
    cursor = Dates.addDays(cursor, 1);
  }

  final totalTasks = days.fold(0, (s, d) => s + d.total);
  final totalCompleted = days.fold(0, (s, d) => s + d.completed);
  return SummaryStat(
    from: from,
    to: to,
    threshold: threshold,
    days: days,
    totalTasks: totalTasks,
    totalCompleted: totalCompleted,
    completionPct: _pct(totalCompleted, totalTasks),
    successfulDays: days.where((d) => d.successful).length,
    activeDays: days.where((d) => d.total > 0).length,
  );
}

/// Current & longest streak of successful days ending at [today]. Equivalent to
/// `GET /stats/streak`, including the grace rule: if today isn't successful yet
/// (still in progress), counting starts from yesterday so an unfinished day
/// doesn't prematurely zero the streak.
StreakStat computeStreak(
  List<Task> tasks, {
  required int threshold,
  required DateTime today,
}) {
  final map = _bucket(tasks);
  bool successful(DateTime d) {
    final c = map[Dates.iso(d)];
    return c != null && c.total > 0 && _pct(c.completed, c.total) >= threshold;
  }

  final windowStart = Dates.addDays(today, -365);

  // Current streak, with grace for an in-progress today.
  var current = 0;
  var cursor = successful(today) ? today : Dates.addDays(today, -1);
  while (!cursor.isBefore(windowStart) && successful(cursor)) {
    current++;
    cursor = Dates.addDays(cursor, -1);
  }

  // Longest streak across the window.
  var longest = 0, run = 0;
  for (var d = windowStart; !d.isAfter(today); d = Dates.addDays(d, 1)) {
    if (successful(d)) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  return StreakStat(
    current: current,
    longest: longest,
    threshold: threshold,
    asOf: Dates.iso(today),
  );
}
