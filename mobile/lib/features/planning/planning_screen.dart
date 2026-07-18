import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/ui_providers.dart';
import '../tasks/widgets/task_tile.dart';

/// Evening Planning: prepare a chosen day (defaults to tomorrow). A Today /
/// Tomorrow quick-switch (any date via the calendar button), a navy summary,
/// generate-from-templates, then the day's tasks.
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  DateTime _date = Dates.tomorrow();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: Dates.today(),
      lastDate: Dates.today().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _generate() async {
    await ref.read(recurringRepositoryProvider).generateForDate(Dates.iso(_date));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.generatingRecurringTasks)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final theme = Theme.of(context);
    final dates = DateLabels(l10n);
    final iso = Dates.iso(_date);
    final tasksAsync = ref.watch(tasksForDayProvider(iso));

    final isToday = Dates.isSameDay(_date, Dates.today());
    final isTomorrow = Dates.isSameDay(_date, Dates.tomorrow());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new', extra: _date),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.navPlan, style: theme.textTheme.displaySmall),
                      const SizedBox(height: 5),
                      Text(l10n.planTonight,
                          style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                _IconChip(
                  icon: Icons.repeat_rounded,
                  onTap: () => context.push('/templates'),
                ),
                const SizedBox(width: 8),
                _IconChip(
                  icon: Icons.edit_calendar_outlined,
                  active: !isToday && !isTomorrow,
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quick Today / Tomorrow switch.
            PillSegment(
              options: [l10n.today, l10n.tomorrow],
              selected: isToday ? 0 : (isTomorrow ? 1 : -1),
              onSelect: (i) => setState(
                  () => _date = i == 0 ? Dates.today() : Dates.tomorrow()),
            ),
            const SizedBox(height: 20),

            // Navy summary card.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.navy,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dates.long(_date),
                            style: TextStyle(
                                fontFamily: AppFonts.sans,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.onNavyMuted)),
                        const SizedBox(height: 6),
                        Text(dates.relative(_date),
                            style: TextStyle(
                                fontFamily: AppFonts.sans,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: c.onNavy)),
                        const SizedBox(height: 6),
                        tasksAsync.maybeWhen(
                          data: (tasks) {
                            final live = tasks
                                .where((t) => t.status != TaskStatus.rescheduled)
                                .length;
                            return Text(l10n.tasksPlanned(live),
                                style: TextStyle(
                                    fontFamily: AppFonts.sans,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: c.onNavyMuted));
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.event_note_rounded, size: 34, color: c.onNavyMuted),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Generate from templates.
            _GhostButton(
              icon: Icons.auto_awesome_rounded,
              label: l10n.generateFromTemplates,
              onTap: _generate,
            ),
            const SizedBox(height: 22),

            Text(l10n.daySchedule, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            tasksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (tasks) => tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: EmptyState(
                        icon: Icons.nightlight_round,
                        title: l10n.nothingPlannedYet,
                        message: l10n.planningEmptyMessage,
                      ),
                    )
                  : Column(
                      children: [
                        for (final t in tasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskTile(t),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.onTap, this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.accentTint : c.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: active ? c.accent : c.textSecondary),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.accentTint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.accent)),
            ],
          ),
        ),
      ),
    );
  }
}
