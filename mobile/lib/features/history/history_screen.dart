import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task.dart';
import '../../data/ui_providers.dart';
import '../auth/auth_controller.dart';
import '../tasks/widgets/task_tile.dart';

/// History / Calendar: a month grid with a per-day completion dot, and the
/// selected day's tasks below. Reads from the cache, so it works offline.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _month = DateTime(Dates.today().year, Dates.today().month);
  DateTime _selected = Dates.today();

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 0); // last day
    final range = (from: Dates.iso(monthStart), to: Dates.iso(monthEnd));
    final monthTasks = ref.watch(tasksInRangeProvider(range)).value ?? const [];
    final threshold =
        ref.watch(authControllerProvider).value?.streakThresholdPct ?? 80;

    // Per-day completion percentage for dots.
    final byDay = <String, ({int total, int done})>{};
    for (final t in monthTasks) {
      if (t.status == TaskStatus.rescheduled) continue;
      final key = Dates.iso(t.planDate);
      final cur = byDay[key] ?? (total: 0, done: 0);
      byDay[key] = (
        total: cur.total + 1,
        done: cur.done + (t.status == TaskStatus.completed ? 1 : 0),
      );
    }

    final selectedIso = Dates.iso(_selected);
    final selectedTasks = ref.watch(tasksForDayProvider(selectedIso)).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: Column(
        children: [
          _MonthHeader(month: _month, onShift: _shiftMonth),
          _CalendarGrid(
            month: _month,
            selected: _selected,
            byDay: byDay,
            threshold: threshold,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(DateLabels(l10n).relative(_selected),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: selectedTasks.isEmpty
                ? EmptyState(
                    icon: Icons.event_available,
                    title: l10n.nothingOnThisDay,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: selectedTasks.length,
                    itemBuilder: (_, i) => TaskTile(selectedTasks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onShift});
  final DateTime month;
  final void Function(int) onShift;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Text(DateLabels.of(context).monthAndYear(month),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(onPressed: () => onShift(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.threshold,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<String, ({int total, int done})> byDay;
  final int threshold;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Leading blanks so the 1st lands under its weekday (Mon-first grid).
    final leadBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;

    final cells = <Widget>[];
    for (var i = 0; i < leadBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final iso = Dates.iso(date);
      final stat = byDay[iso];
      final isSelected = Dates.isSameDay(date, selected);
      final isToday = Dates.isSameDay(date, Dates.today());

      Color? dot;
      if (stat != null && stat.total > 0) {
        final pct = stat.done / stat.total * 100;
        dot = pct >= threshold
            ? Colors.green
            : (stat.done > 0 ? Colors.amber.shade700 : theme.colorScheme.outline);
      }

      cells.add(GestureDetector(
        onTap: () => onSelect(date),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : null,
                border: isToday && !isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Text('$day',
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : null,
                    fontWeight: isToday ? FontWeight.bold : null,
                  )),
            ),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot ?? Colors.transparent,
              ),
            ),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final d in DateLabels.of(context).weekdayHeadings)
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.72,
            children: cells,
          ),
        ],
      ),
    );
  }
}
