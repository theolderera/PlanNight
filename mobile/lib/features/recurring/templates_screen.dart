import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/recurring_template.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/ui_providers.dart';

/// Manage recurring task templates (the blueprints that generate daily tasks).
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  /// "Every day", or the selected weekdays in week order ("Mon, Wed, Fri").
  ///
  /// `daysOfWeek` uses the API's numbering (0 = Sunday .. 6 = Saturday), while
  /// [DateLabels.weekdayShort] uses Dart's (1 = Monday .. 7 = Sunday), so a day
  /// `d` maps to `d == 0 ? DateTime.sunday : d`.
  static String recurrenceLabel(RecurringTemplate t, AppLocalizations l10n) {
    if (t.recurrenceType == RecurrenceType.daily) return l10n.everyDay;
    final dates = DateLabels(l10n);
    const weekOrder = [1, 2, 3, 4, 5, 6, 0]; // Mon..Sun, in API numbering
    return [
      for (final d in weekOrder)
        if (t.daysOfWeek.contains(d))
          dates.weekdayShort(d == 0 ? DateTime.sunday : d),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dates = DateLabels(l10n);
    final templatesAsync = ref.watch(templatesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTemplates)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/template/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newTemplate),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (templates) => templates.isEmpty
            ? EmptyState(
                icon: Icons.repeat,
                title: l10n.noRecurringTasks,
                message: l10n.noRecurringTasksMessage,
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: templates.length,
                itemBuilder: (_, i) {
                  final t = templates[i];
                  final category = t.categoryId == null
                      ? null
                      : ref.watch(categoriesByIdProvider)[t.categoryId];
                  final subtitle = [
                    dates.time(context, t.startTime),
                    recurrenceLabel(t, l10n),
                    if (!t.active) l10n.paused,
                  ].join(' · ');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (category?.color ?? Theme.of(context).colorScheme.primary)
                              .withValues(alpha: 0.15),
                      child: Icon(Icons.repeat,
                          color: category?.color ??
                              Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(t.title,
                        style: TextStyle(
                            decoration:
                                t.active ? null : TextDecoration.lineThrough)),
                    subtitle: Text(subtitle),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        final repo = ref.read(recurringRepositoryProvider);
                        switch (v) {
                          case 'edit':
                            context.push('/template/edit', extra: t);
                          case 'toggle':
                            await repo.update(_toggled(t));
                          case 'delete':
                            await repo.delete(t);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(t.active ? l10n.pause : l10n.resume)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                    onTap: () => context.push('/template/edit', extra: t),
                  );
                },
              ),
      ),
    );
  }

  RecurringTemplate _toggled(RecurringTemplate t) => RecurringTemplate(
        id: t.id,
        title: t.title,
        notes: t.notes,
        categoryId: t.categoryId,
        priority: t.priority,
        startTime: t.startTime,
        durationMinutes: t.durationMinutes,
        reminderLeadMinutes: t.reminderLeadMinutes,
        recurrenceType: t.recurrenceType,
        daysOfWeek: t.daysOfWeek,
        active: !t.active,
      );
}
