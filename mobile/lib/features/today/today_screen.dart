import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task.dart';
import '../../data/ui_providers.dart';
import '../tasks/widgets/task_tile.dart';

/// The Today view: tasks for a chosen day (defaults to today) in chronological
/// order, with a completion header, category/priority filters, and check-off.
/// Reads entirely from the offline cache, so it works with no connection.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  DateTime _date = Dates.today();
  String? _filterCategoryId;
  Priority? _filterPriority;

  void _shiftDay(int delta) =>
      setState(() => _date = Dates.addDays(_date, delta));

  List<Task> _applyFilters(List<Task> tasks) {
    return tasks.where((t) {
      if (_filterCategoryId != null && t.categoryId != _filterCategoryId) {
        return false;
      }
      if (_filterPriority != null && t.priority != _filterPriority) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = DateLabels(l10n);
    final iso = Dates.iso(_date);
    final tasksAsync = ref.watch(tasksForDayProvider(iso));

    return Scaffold(
      appBar: AppBar(
        title: Text(dates.relative(_date)),
        actions: [
          const _SyncIndicator(),
          IconButton(
            tooltip: l10n.filter,
            icon: Icon(
              _filterCategoryId != null || _filterPriority != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task/new', extra: _date),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
      ),
      body: Column(
        children: [
          _DateBar(
            date: _date,
            onShift: _shiftDay,
            onPickToday: () => setState(() => _date = Dates.today()),
          ),
          tasksAsync.when(
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                Expanded(child: Center(child: Text(l10n.errorWithMessage('$e')))),
            data: (allTasks) {
              final tasks = _applyFilters(allTasks);
              return Expanded(
                child: Column(
                  children: [
                    _ProgressHeader(tasks: allTasks),
                    Expanded(
                      child: tasks.isEmpty
                          ? EmptyState(
                              icon: Icons.checklist_rtl,
                              title: allTasks.isEmpty ? l10n.nothingPlanned : l10n.noMatches,
                              message: allTasks.isEmpty
                                  ? l10n.nothingPlannedMessage
                                  : l10n.noMatchesMessage,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 96, top: 4),
                              itemCount: tasks.length,
                              itemBuilder: (_, i) => TaskTile(tasks[i]),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final l10n = context.l10n;
    final categories = ref.read(categoriesStreamProvider).value ?? const [];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          void apply(VoidCallback fn) {
            setSheet(fn);
            setState(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.priority, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: _filterPriority == null,
                      onSelected: (_) => apply(() => _filterPriority = null),
                    ),
                    for (final p in Priority.values)
                      ChoiceChip(
                        label: Text(p.label(l10n)),
                        selected: _filterPriority == p,
                        onSelected: (_) => apply(() => _filterPriority = p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.category, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: _filterCategoryId == null,
                      onSelected: (_) => apply(() => _filterCategoryId = null),
                    ),
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _filterCategoryId == c.id,
                        onSelected: (_) => apply(() => _filterCategoryId = c.id),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.date, required this.onShift, required this.onPickToday});
  final DateTime date;
  final void Function(int) onShift;
  final VoidCallback onPickToday;

  @override
  Widget build(BuildContext context) {
    final isToday = Dates.isSameDay(date, Dates.today());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Text(DateLabels.of(context).long(date),
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          if (!isToday)
            TextButton(onPressed: onPickToday, child: Text(context.l10n.today)),
          IconButton(onPressed: () => onShift(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

/// Daily completion summary computed locally from the day's tasks.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Denominator excludes rescheduled tasks (they moved elsewhere).
    final counted = tasks.where((t) => t.status != TaskStatus.rescheduled).toList();
    final total = counted.length;
    final done = counted.where((t) => t.status == TaskStatus.completed).length;
    final pct = total == 0 ? 0.0 : done / total;

    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.progressDone(done, total),
                  style: theme.textTheme.labelLarge),
              Text('${(pct * 100).round()}%',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: pct, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

/// Small header indicator showing how many local changes are awaiting sync.
class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    if (pending == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 18),
            const SizedBox(width: 4),
            Text('$pending', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
