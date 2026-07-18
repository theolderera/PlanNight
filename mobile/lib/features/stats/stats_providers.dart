import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stats.dart';
import '../../data/repositories/stats_repository.dart';

/// A date range key for the summary family provider.
typedef DateRange = ({String from, String to});

/// Weekly (or any-range) summary from the API.
final summaryProvider =
    FutureProvider.family<SummaryStat, DateRange>((ref, range) {
  return ref.watch(statsRepositoryProvider).summary(from: range.from, to: range.to);
});

/// Current & longest streak from the API.
final streakProvider = FutureProvider<StreakStat>((ref) {
  return ref.watch(statsRepositoryProvider).streak();
});
