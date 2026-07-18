import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/recurring_template.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/ui_providers.dart';

/// Manage recurring task templates (the blueprints that generate daily tasks).
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  /// "Every day", or the selected weekdays in week order.
  ///
  /// `daysOfWeek` uses the API's numbering (0 = Sunday .. 6 = Saturday), while
  /// [DateLabels.weekdayShort] uses Dart's (1 = Monday .. 7 = Sunday), so a day
  /// `d` maps to `d == 0 ? DateTime.sunday : d`.
  static String recurrenceLabel(RecurringTemplate t, AppLocalizations l10n) {
    if (t.recurrenceType == RecurrenceType.daily) return l10n.everyDay;
    final dates = DateLabels(l10n);
    const weekOrder = [1, 2, 3, 4, 5, 6, 0];
    return [
      for (final d in weekOrder)
        if (t.daysOfWeek.contains(d)) dates.weekdayShort(d == 0 ? DateTime.sunday : d),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dates = DateLabels(l10n);
    final templatesAsync = ref.watch(templatesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.recurringTemplates,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/template/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newTemplate),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (templates) => templates.isEmpty
            ? EmptyState(
                icon: Icons.repeat_rounded,
                title: l10n.noRecurringTasks,
                message: l10n.noRecurringTasksMessage,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  for (final t in templates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TemplateRow(
                        template: t,
                        category: t.categoryId == null
                            ? null
                            : ref.watch(categoriesByIdProvider)[t.categoryId],
                        subtitle: [
                          dates.time(context, t.startTime),
                          recurrenceLabel(t, l10n),
                          if (!t.active) l10n.paused,
                        ].join('  ·  '),
                        onEdit: () => context.push('/template/edit', extra: t),
                        onToggle: () => ref.read(recurringRepositoryProvider).update(_toggled(t)),
                        onDelete: () => ref.read(recurringRepositoryProvider).delete(t),
                      ),
                    ),
                ],
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

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.template,
    required this.category,
    required this.subtitle,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringTemplate template;
  final dynamic category; // Category?
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final color = category?.color ?? c.accent;

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: onEdit,
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color as Color).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.repeat_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: template.active ? c.ink : c.textMuted,
                      decoration: template.active ? null : TextDecoration.lineThrough,
                    )),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.mono, fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: c.textMuted),
            onSelected: (v) => switch (v) {
              'edit' => onEdit(),
              'toggle' => onToggle(),
              'delete' => onDelete(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: _MenuRow(Icons.edit_outlined, l10n.edit)),
              PopupMenuItem(
                  value: 'toggle',
                  child: _MenuRow(template.active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      template.active ? l10n.pause : l10n.resume)),
              PopupMenuItem(value: 'delete', child: _MenuRow(Icons.delete_outline_rounded, l10n.delete, danger: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.danger : c.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, color: danger ? c.danger : c.ink)),
      ],
    );
  }
}
