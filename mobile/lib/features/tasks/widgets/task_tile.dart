import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/date_utils.dart';
import '../../../core/l10n.dart';
import '../../../data/models/category.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/ui_providers.dart';

/// A single task row: check-off control, time, title, category & priority, and
/// an actions menu (edit / skip / reschedule / delete). Reused by Today and
/// History.
class TaskTile extends ConsumerWidget {
  const TaskTile(this.task, {super.key, this.readOnly = false});

  final Task task;

  /// When true (e.g. viewing a past day in history), actions are hidden.
  final bool readOnly;

  Color _priorityColor(ColorScheme scheme) => switch (task.priority) {
        Priority.high => Colors.redAccent,
        Priority.medium => Colors.amber.shade700,
        Priority.low => scheme.outline,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final category = task.categoryId == null
        ? null
        : ref.watch(categoriesByIdProvider)[task.categoryId];
    final repo = ref.read(taskRepositoryProvider);

    final isDone = task.status == TaskStatus.completed;
    final isSkipped = task.status == TaskStatus.skipped;
    final isRescheduled = task.status == TaskStatus.rescheduled;
    final muted = isDone || isSkipped || isRescheduled;

    // "09:30 · moved" — the suffix explains why a task looks struck through.
    final time = DateLabels(l10n).time(context, task.startTime);
    final subtitle = switch (task.status) {
      TaskStatus.rescheduled => '$time · ${l10n.taskMoved}',
      TaskStatus.skipped => '$time · ${l10n.taskSkipped}',
      _ => time,
    };

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Category colour accent.
            Container(
              width: 4,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: (category?.color ?? scheme.outlineVariant),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Check-off control.
            _StatusControl(
              status: task.status,
              onToggle: readOnly
                  ? null
                  : () => repo.setStatus(
                        task,
                        isDone ? TaskStatus.planned : TaskStatus.completed,
                      ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: muted ? TextDecoration.lineThrough : null,
                      color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      if (category != null) ...[
                        const SizedBox(width: 8),
                        _CategoryChip(category),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Priority dot.
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _priorityColor(scheme),
                shape: BoxShape.circle,
              ),
            ),
            if (!readOnly)
              _TaskMenu(task: task, repo: repo),
          ],
        ),
      ),
    );

    if (readOnly) return card;

    // Swipe shortcuts for the two most frequent actions. `confirmDismiss`
    // performs the action and returns false, so the tile is never removed from
    // the tree — the optimistic cache write re-renders it in its new state
    // (and a second swipe undoes, since both actions toggle).
    return Dismissible(
      key: ValueKey('swipe-${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await repo.setStatus(
              task, isDone ? TaskStatus.planned : TaskStatus.completed);
        } else {
          await repo.setStatus(
              task, isSkipped ? TaskStatus.planned : TaskStatus.skipped);
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: scheme.primary,
        icon: isDone ? Icons.undo : Icons.check_circle_outline,
        label: isDone ? l10n.markNotDone : l10n.markDone,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.error,
        icon: isSkipped ? Icons.undo : Icons.cancel_outlined,
        label: l10n.skip,
      ),
      child: card,
    );
  }
}

/// The coloured strip revealed behind a task while swiping.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusControl extends StatelessWidget {
  const _StatusControl({required this.status, required this.onToggle});
  final TaskStatus status;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (icon, color) = switch (status) {
      TaskStatus.completed => (Icons.check_circle, scheme.primary),
      TaskStatus.skipped => (Icons.cancel, scheme.error),
      TaskStatus.rescheduled => (Icons.event_repeat, scheme.tertiary),
      TaskStatus.planned => (Icons.radio_button_unchecked, scheme.outline),
    };
    return IconButton(
      onPressed: onToggle,
      icon: Icon(icon, color: color),
      visualDensity: VisualDensity.compact,
      tooltip: status == TaskStatus.completed ? l10n.markNotDone : l10n.markDone,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.category);
  final Category category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.name,
        style: TextStyle(fontSize: 11, color: category.color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TaskMenu extends StatelessWidget {
  const _TaskMenu({required this.task, required this.repo});
  final Task task;
  final TaskRepository repo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            context.push('/task/edit', extra: task);
          case 'skip':
            await repo.setStatus(task, TaskStatus.skipped);
          case 'reschedule':
            final picked = await showDatePicker(
              context: context,
              initialDate: Dates.tomorrow(),
              firstDate: Dates.today().subtract(const Duration(days: 365)),
              lastDate: Dates.today().add(const Duration(days: 365)),
            );
            if (picked != null) await repo.reschedule(task, picked);
          case 'delete':
            await repo.delete(task);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.edit)),
        ),
        PopupMenuItem(
          value: 'skip',
          child: ListTile(leading: const Icon(Icons.cancel_outlined), title: Text(l10n.skip)),
        ),
        PopupMenuItem(
          value: 'reschedule',
          child: ListTile(leading: const Icon(Icons.event_repeat), title: Text(l10n.reschedule)),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete)),
        ),
      ],
    );
  }
}
