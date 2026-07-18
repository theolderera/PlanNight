// Stats DTOs mirroring the `/stats/*` endpoints.

/// One day's completion breakdown (`GET /stats/daily`, and each entry of
/// `GET /stats/summary`).
class DayStat {
  const DayStat({
    required this.date,
    required this.total,
    required this.completed,
    required this.skipped,
    required this.pending,
    required this.completionPct,
    required this.successful,
  });

  final String date; // 'YYYY-MM-DD'
  final int total;
  final int completed;
  final int skipped;
  final int pending;
  final int completionPct;
  final bool successful;

  factory DayStat.fromJson(Map<String, dynamic> json) => DayStat(
        date: json['date'] as String,
        total: (json['total'] as num).toInt(),
        completed: (json['completed'] as num).toInt(),
        skipped: (json['skipped'] as num).toInt(),
        pending: (json['pending'] as num).toInt(),
        completionPct: (json['completionPct'] as num).toInt(),
        successful: json['successful'] as bool,
      );
}

/// A range summary: per-day breakdown plus totals (`GET /stats/summary`).
class SummaryStat {
  const SummaryStat({
    required this.from,
    required this.to,
    required this.threshold,
    required this.days,
    required this.totalTasks,
    required this.totalCompleted,
    required this.completionPct,
    required this.successfulDays,
    required this.activeDays,
  });

  final String from;
  final String to;
  final int threshold;
  final List<DayStat> days;
  final int totalTasks;
  final int totalCompleted;
  final int completionPct;
  final int successfulDays;
  final int activeDays;

  factory SummaryStat.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return SummaryStat(
      from: json['from'] as String,
      to: json['to'] as String,
      threshold: (json['threshold'] as num).toInt(),
      days: (json['days'] as List)
          .map((e) => DayStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTasks: (totals['totalTasks'] as num).toInt(),
      totalCompleted: (totals['totalCompleted'] as num).toInt(),
      completionPct: (totals['completionPct'] as num).toInt(),
      successfulDays: (totals['successfulDays'] as num).toInt(),
      activeDays: (totals['activeDays'] as num).toInt(),
    );
  }
}

/// Current & longest streak (`GET /stats/streak`).
class StreakStat {
  const StreakStat({
    required this.current,
    required this.longest,
    required this.threshold,
    required this.asOf,
  });

  final int current;
  final int longest;
  final int threshold;
  final String asOf;

  factory StreakStat.fromJson(Map<String, dynamic> json) => StreakStat(
        current: (json['current'] as num).toInt(),
        longest: (json['longest'] as num).toInt(),
        threshold: (json['threshold'] as num).toInt(),
        asOf: json['asOf'] as String,
      );
}
