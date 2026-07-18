import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task.dart';
import '../../data/models/user_profile.dart';
import '../../data/ui_providers.dart';
import '../auth/auth_controller.dart';
import '../stats/stats_providers.dart';
import '../tasks/widgets/task_tile.dart';

/// The Today view: a warm greeting, a navy progress hero (completion ring +
/// streak), a day navigator, and the day's task schedule. Reads entirely from
/// the offline cache, so it works with no connection.
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

  bool get _hasFilter => _filterCategoryId != null || _filterPriority != null;

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
    final c = context.colors;
    final iso = Dates.iso(_date);
    final tasksAsync = ref.watch(tasksForDayProvider(iso));
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new', extra: _date),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        bottom: false,
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
          data: (allTasks) {
            final filtered = _applyFilters(allTasks);
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(streakProvider),
              color: c.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  _Header(user: user, date: _date),
                  const SizedBox(height: 20),
                  _ProgressHero(tasks: allTasks),
                  const SizedBox(height: 22),
                  _DayNavigator(
                    date: _date,
                    onShift: _shiftDay,
                    onToday: () => setState(() => _date = Dates.today()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(l10n.daySchedule,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      _FilterButton(active: _hasFilter, onTap: _openFilters),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: EmptyState(
                        icon: Icons.checklist_rtl_rounded,
                        title: allTasks.isEmpty ? l10n.nothingPlanned : l10n.noMatches,
                        message: allTasks.isEmpty
                            ? l10n.nothingPlannedMessage
                            : l10n.noMatchesMessage,
                      ),
                    )
                  else
                    for (final t in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskTile(t),
                      ),
                ],
              ),
            );
          },
        ),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.priority, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
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
                const SizedBox(height: 18),
                Text(l10n.category, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: _filterCategoryId == null,
                      onSelected: (_) => apply(() => _filterCategoryId = null),
                    ),
                    for (final cat in categories)
                      ChoiceChip(
                        avatar: CircleAvatar(backgroundColor: cat.color, radius: 5),
                        label: Text(cat.name),
                        selected: _filterCategoryId == cat.id,
                        onSelected: (_) => apply(() => _filterCategoryId = cat.id),
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

/// Derives a friendly display name and initial from the user's email.
({String name, String initial}) _identity(UserProfile? user) {
  final email = user?.email ?? '';
  final local = email.contains('@') ? email.split('@').first : email;
  final cleaned = local.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
  final name = cleaned.isEmpty
      ? 'PlanNight'
      : cleaned[0].toUpperCase() + cleaned.substring(1);
  final initial = name[0].toUpperCase();
  return (name: name, initial: initial);
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.date});
  final UserProfile? user;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final l10n = context.l10n;
    final id = _identity(user);
    final isToday = Dates.isSameDay(date, Dates.today());
    final dates = DateLabels(l10n);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? l10n.greeting(id.name) : dates.relative(date),
                style: theme.textTheme.displaySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(dates.long(date),
                  style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.navy,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(id.initial,
              style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.onNavy)),
        ),
      ],
    );
  }
}

/// The navy hero: a completion ring, a message, and the current streak.
class _ProgressHero extends ConsumerWidget {
  const _ProgressHero({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;

    final counted = tasks.where((t) => t.status != TaskStatus.rescheduled).toList();
    final total = counted.length;
    final done = counted.where((t) => t.status == TaskStatus.completed).length;
    final pct = total == 0 ? 0.0 : done / total;
    final streakAsync = ref.watch(streakProvider);

    final message = total == 0
        ? l10n.nothingPlanned
        : (done >= total ? l10n.allDone : '${l10n.progressDone(done, total)} · ${l10n.keepGoing}');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Positioned(
              right: -46,
              top: -46,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [c.navyRingFill.withValues(alpha: 0.35), Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                ProgressRing(
                  progress: pct,
                  size: 88,
                  trackColor: c.navyRingTrack,
                  fillColor: c.navyRingFill,
                  child: Text('${(pct * 100).round()}%',
                      style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: c.onNavy)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.todaysProgress,
                          style: TextStyle(
                              fontFamily: AppFonts.sans,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.onNavy)),
                      const SizedBox(height: 5),
                      Text(message,
                          style: TextStyle(
                              fontFamily: AppFonts.sans,
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: c.onNavyMuted)),
                      streakAsync.maybeWhen(
                        data: (s) => s.current <= 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _StreakChip(count: s.current),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 15, color: c.amber),
          const SizedBox(width: 5),
          Text(context.l10n.streakDays(count),
              style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.onNavy)),
        ],
      ),
    );
  }
}

/// Compact day navigator: chevrons around the relative day label, which taps
/// back to today when you've navigated away.
class _DayNavigator extends StatelessWidget {
  const _DayNavigator({required this.date, required this.onShift, required this.onToday});
  final DateTime date;
  final void Function(int) onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isToday = Dates.isSameDay(date, Dates.today());
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: c.textSecondary,
          ),
          Expanded(
            child: GestureDetector(
              onTap: isToday ? null : onToday,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateLabels.of(context).relative(date),
                        style: Theme.of(context).textTheme.titleSmall),
                    if (!isToday) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.today_rounded, size: 15, color: c.accent),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onShift(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.accentTint : c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                  size: 18, color: active ? c.accent : c.textSecondary),
              const SizedBox(width: 6),
              Text(context.l10n.filter,
                  style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? c.accent : c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
