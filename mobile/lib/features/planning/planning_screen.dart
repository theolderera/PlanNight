import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/ui_providers.dart';
import '../tasks/widgets/task_tile.dart';

/// Evening Planning: prepare a chosen day (defaults to tomorrow). Generate the
/// day's recurring tasks from templates, then add/adjust one-off tasks.
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
    final dates = DateLabels(l10n);
    final iso = Dates.iso(_date);
    final tasksAsync = ref.watch(tasksForDayProvider(iso));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlan),
        actions: [
          IconButton(
            tooltip: l10n.recurringTemplates,
            icon: const Icon(Icons.repeat),
            onPressed: () => context.push('/templates'),
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
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.event_note),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.planningFor,
                            style: Theme.of(context).textTheme.labelSmall),
                        Text(dates.relative(_date),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(dates.long(_date),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar),
                    label: Text(l10n.change),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.generateFromTemplates),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
              data: (tasks) => tasks.isEmpty
                  ? EmptyState(
                      icon: Icons.nightlight_round,
                      title: l10n.nothingPlannedYet,
                      message: l10n.planningEmptyMessage,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96, top: 4),
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => TaskTile(tasks[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
