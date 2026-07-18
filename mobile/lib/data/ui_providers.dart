import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'models/category.dart';
import 'models/recurring_template.dart';
import 'models/task.dart';
import 'repositories/category_repository.dart';
import 'repositories/recurring_repository.dart';
import 'repositories/task_repository.dart';

/// Reactive UI providers backed by the offline cache. Screens watch these and
/// automatically rebuild as the cache changes (from local edits or sync).

/// Live categories.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

/// Convenience lookup: category id -> Category (for colouring task rows).
final categoriesByIdProvider = Provider<Map<String, Category>>((ref) {
  final categories = ref.watch(categoriesStreamProvider).value ?? const [];
  return {for (final c in categories) c.id: c};
});

/// Live tasks for a single 'YYYY-MM-DD' day.
final tasksForDayProvider =
    StreamProvider.family<List<Task>, String>((ref, date) {
  return ref.watch(taskRepositoryProvider).watchDay(date);
});

/// Live tasks across an inclusive date range 'from|to' (packed as "from|to").
final tasksInRangeProvider =
    StreamProvider.family<List<Task>, ({String from, String to})>((ref, range) {
  return ref.watch(taskRepositoryProvider).watchRange(range.from, range.to);
});

/// Live recurring templates.
final templatesStreamProvider = StreamProvider<List<RecurringTemplate>>((ref) {
  return ref.watch(recurringRepositoryProvider).watchAll();
});

/// Number of queued (not-yet-synced) local writes, for a sync indicator.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).watchPendingCount();
});
