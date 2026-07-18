import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task.dart';
import '../../data/ui_providers.dart';
import '../auth/auth_controller.dart';
import '../tasks/widgets/task_tile.dart';

/// History / Calendar: a month grid with a per-day completion dot (against the
/// user's "good day" threshold), and the selected day's tasks below. Reads from
/// the cache, so it works offline.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _month = DateTime(Dates.today().year, Dates.today().month);
  DateTime _selected = Dates.today();

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final range = (from: Dates.iso(monthStart), to: Dates.iso(monthEnd));
    final monthTasks = ref.watch(tasksInRangeProvider(range)).value ?? const [];
    final threshold =
        ref.watch(authControllerProvider).value?.streakThresholdPct ?? 80;

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
    final counted = selectedTasks.where((t) => t.status != TaskStatus.rescheduled).toList();
    final selPct = counted.isEmpty
        ? null
        : (counted.where((t) => t.status == TaskStatus.completed).length / counted.length * 100).round();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.navHistory, style: theme.textTheme.displaySmall),
            const SizedBox(height: 18),
            _CalendarCard(
              month: _month,
              selected: _selected,
              byDay: byDay,
              threshold: threshold,
              onShift: _shiftMonth,
              onSelect: (d) => setState(() => _selected = d),
            ),
            const SizedBox(height: 16),
            _Legend(),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(DateLabels(l10n).relative(_selected),
                      style: theme.textTheme.titleMedium),
                ),
                if (selPct != null)
                  Text('$selPct%',
                      style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.accent)),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EmptyState(
                  icon: Icons.event_available_rounded,
                  title: l10n.nothingOnThisDay,
                ),
              )
            else
              for (final t in selectedTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskTile(t, readOnly: true),
                ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.threshold,
    required this.onShift,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<String, ({int total, int done})> byDay;
  final int threshold;
  final void Function(int) onShift;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final dates = DateLabels(l10n);
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -4)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _NavBox(icon: Icons.chevron_left_rounded, onTap: () => onShift(-1)),
              Expanded(
                child: Center(
                  child: Text(dates.monthAndYear(month),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              _NavBox(icon: Icons.chevron_right_rounded, onTap: () => onShift(1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final d in dates.weekdayHeadings)
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: TextStyle(
                            fontFamily: AppFonts.sans, fontSize: 10, fontWeight: FontWeight.w700, color: c.textFaint)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < leadBlanks; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _DayCell(
                  date: DateTime(month.year, month.month, day),
                  selected: selected,
                  byDay: byDay,
                  threshold: threshold,
                  onSelect: onSelect,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.byDay,
    required this.threshold,
    required this.onSelect,
  });
  final DateTime date;
  final DateTime selected;
  final Map<String, ({int total, int done})> byDay;
  final int threshold;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iso = Dates.iso(date);
    final stat = byDay[iso];
    final isSelected = Dates.isSameDay(date, selected);
    final isToday = Dates.isSameDay(date, Dates.today());

    Color dot = Colors.transparent;
    if (stat != null && stat.total > 0) {
      final pct = stat.done / stat.total * 100;
      dot = pct >= threshold ? c.success : (stat.done > 0 ? c.amber : c.border);
    }

    return GestureDetector(
      onTap: () => onSelect(date),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? c.accent : null,
              borderRadius: BorderRadius.circular(11),
              border: isToday && !isSelected ? Border.all(color: c.accent, width: 1.5) : null,
            ),
            child: Text('${date.day}',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12.5,
                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isToday ? c.accent : c.ink),
                )),
          ),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected && dot != Colors.transparent ? Colors.white : dot,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBox extends StatelessWidget {
  const _NavBox({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: c.textSecondary),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          item(c.success, l10n.legendGoodDay),
          const SizedBox(width: 16),
          item(c.amber, l10n.legendPartial),
          const SizedBox(width: 16),
          item(c.border, l10n.legendEmpty),
        ],
      ),
    );
  }
}
