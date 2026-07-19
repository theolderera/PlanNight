import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../data/models/stats.dart';
import '../../data/repositories/task_repository.dart';
import '../auth/auth_controller.dart';
import 'stats_calc.dart';

/// A date range key for the summary family provider.
typedef DateRange = ({String from, String to});

/// The user's "successful day" threshold (default 80% until the profile loads).
final _thresholdProvider = Provider<int>((ref) =>
    ref.watch(authControllerProvider).value?.streakThresholdPct ?? 80);

/// Weekly (or any-range) summary, computed locally from the cached tasks so it
/// works offline and updates reactively the moment a task changes.
final summaryProvider =
    StreamProvider.family<SummaryStat, DateRange>((ref, range) {
  final threshold = ref.watch(_thresholdProvider);
  return ref.watch(taskRepositoryProvider).watchRange(range.from, range.to).map(
        (tasks) => computeSummary(tasks,
            from: range.from, to: range.to, threshold: threshold),
      );
});

/// Current & longest streak, computed locally over a one-year window.
final streakProvider = StreamProvider<StreakStat>((ref) {
  final threshold = ref.watch(_thresholdProvider);
  final today = Dates.today();
  final from = Dates.iso(Dates.addDays(today, -365));
  final to = Dates.iso(today);
  return ref.watch(taskRepositoryProvider).watchRange(from, to).map(
        (tasks) => computeStreak(tasks, threshold: threshold, today: today),
      );
});
