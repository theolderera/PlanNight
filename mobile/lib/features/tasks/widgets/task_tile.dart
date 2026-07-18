import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/date_utils.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../data/models/category.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/ui_providers.dart';

/// A single task row in the redesigned style: a status control, the title with
/// a time/category caption, a "NOW" marker for the task happening this minute,
/// and a category colour accent. Tap to edit, swipe right to complete, swipe
/// left to skip, long-press for more actions. Reused (read-only) by History.
class TaskTile extends ConsumerWidget {
  const TaskTile(this.task, {super.key, this.readOnly = false});

  final Task task;

  /// When true (e.g. viewing a past day in history), actions are hidden.
  final bool readOnly;

  /// True when this timed, still-pending task's window contains the current
  /// moment (today only). Gives the "NOW" accent + border.
  bool get _isNow {
    if (task.status != TaskStatus.planned || task.startTime == null) return false;
    if (!Dates.isSameDay(task.planDate, Dates.today())) return false;
    final tod = task.startTimeOfDay;
    if (tod == null) return false;
    final now = TimeOfDay.now();
    final startMin = tod.hour * 60 + tod.minute;
    final nowMin = now.hour * 60 + now.minute;
    final span = task.durationMinutes ?? 60;
    return nowMin >= startMin && nowMin < startMin + span;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final category = task.categoryId == null
        ? null
        : ref.watch(categoriesByIdProvider)[task.categoryId];
    final repo = ref.read(taskRepositoryProvider);

    final isDone = task.status == TaskStatus.completed;
    final isSkipped = task.status == TaskStatus.skipped;
    final isRescheduled = task.status == TaskStatus.rescheduled;
    final muted = isDone || isSkipped || isRescheduled;
    final isNow = _isNow;

    final accentColor = category?.color ?? c.textFaint;

    final card = Opacity(
      opacity: isDone || isRescheduled ? 0.62 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: isNow ? Border.all(color: c.accent, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: isNow ? c.accent.withValues(alpha: 0.18) : c.shadow,
              blurRadius: isNow ? 18 : 10,
              offset: Offset(0, isNow ? 6 : 2),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            _StatusControl(
              status: task.status,
              onToggle: readOnly
                  ? null
                  : () => repo.setStatus(
                        task,
                        isDone ? TaskStatus.planned : TaskStatus.completed,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 14,
                      fontWeight: isNow ? FontWeight.w700 : FontWeight.w600,
                      decoration: muted ? TextDecoration.lineThrough : null,
                      color: muted ? c.textMuted : c.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _Caption(task: task, category: category, isNow: isNow),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );

    if (readOnly) return card;

    final interactive = GestureDetector(
      onTap: () => context.push('/task/edit', extra: task),
      onLongPress: () => _showActions(context, repo, l10n),
      child: card,
    );

    // Swipe: right = complete/undo, left = skip/undo. confirmDismiss performs
    // the action and returns false, so the row stays and re-renders in its new
    // state (a second swipe undoes, since both actions toggle).
    return Dismissible(
      key: ValueKey('swipe-${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await repo.setStatus(task, isDone ? TaskStatus.planned : TaskStatus.completed);
        } else {
          await repo.setStatus(task, isSkipped ? TaskStatus.planned : TaskStatus.skipped);
        }
        return false;
      },
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: c.success,
        icon: isDone ? Icons.undo_rounded : Icons.check_rounded,
        label: isDone ? l10n.markNotDone : l10n.markDone,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: c.textMuted,
        icon: isSkipped ? Icons.undo_rounded : Icons.close_rounded,
        label: l10n.skip,
      ),
      child: interactive,
    );
  }

  Future<void> _showActions(BuildContext context, TaskRepository repo, AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionRow(
              icon: Icons.edit_outlined,
              label: l10n.edit,
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/task/edit', extra: task);
              },
            ),
            _ActionRow(
              icon: Icons.event_repeat_rounded,
              label: l10n.reschedule,
              onTap: () async {
                Navigator.pop(sheetCtx);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: Dates.tomorrow(),
                  firstDate: Dates.today().subtract(const Duration(days: 365)),
                  lastDate: Dates.today().add(const Duration(days: 365)),
                );
                if (picked != null) await repo.reschedule(task, picked);
              },
            ),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              danger: true,
              onTap: () {
                Navigator.pop(sheetCtx);
                repo.delete(task);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.task, required this.category, required this.isNow});
  final Task task;
  final Category? category;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final time = DateLabels(l10n).time(context, task.startTime);

    final parts = <(String, Color)>[(time, c.textMuted)];
    if (category != null) parts.add((category!.name, c.textMuted));
    if (isNow) {
      parts.add((l10n.now, c.accent));
    } else if (task.status == TaskStatus.rescheduled) {
      parts.add((l10n.taskMoved, c.textMuted));
    } else if (task.status == TaskStatus.skipped) {
      parts.add((l10n.taskSkipped, c.textMuted));
    }

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: c.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0)
                    TextSpan(
                        text: '  ·  ',
                        style: TextStyle(color: c.textFaint, fontWeight: FontWeight.w600)),
                  TextSpan(
                    text: parts[i].$1,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: parts[i].$2,
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusControl extends StatelessWidget {
  const _StatusControl({required this.status, required this.onToggle});
  final TaskStatus status;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget box;
    switch (status) {
      case TaskStatus.completed:
        box = Container(
          decoration: BoxDecoration(color: c.success, borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
        );
      case TaskStatus.skipped:
        box = Container(
          decoration: BoxDecoration(color: c.textMuted, borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
        );
      case TaskStatus.rescheduled:
        box = Container(
          decoration: BoxDecoration(color: c.accentTint, borderRadius: BorderRadius.circular(9)),
          child: Icon(Icons.event_repeat_rounded, size: 15, color: c.accent),
        );
      case TaskStatus.planned:
        box = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.border, width: 2),
          ),
        );
    }

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 26, height: 26, child: box),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.alignment, required this.color, required this.icon, required this.label});
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final right = alignment == Alignment.centerRight;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!right) Icon(icon, color: Colors.white, size: 20),
          if (!right) const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          if (right) const SizedBox(width: 8),
          if (right) Icon(icon, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.danger : c.ink;
    return ListTile(
      leading: Icon(icon, color: danger ? c.danger : c.textSecondary),
      title: Text(label,
          style: TextStyle(
              fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }
}
