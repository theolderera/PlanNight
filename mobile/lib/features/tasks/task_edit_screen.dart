import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/reminder_options.dart';
import '../../data/api/api_error.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/ui_providers.dart';

/// Create or edit a task. Pass an existing [task] to edit, or [initialDate] to
/// create a new one pre-set to that day.
class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({super.key, this.task, this.initialDate});

  final Task? task;
  final DateTime? initialDate;

  bool get isEditing => task != null;

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _duration;

  String? _categoryId;
  Priority _priority = Priority.medium;
  late DateTime _planDate;
  TimeOfDay? _startTime;
  int _reminderLead = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _duration = TextEditingController(
        text: t?.durationMinutes != null ? '${t!.durationMinutes}' : '');
    _categoryId = t?.categoryId;
    _priority = t?.priority ?? Priority.medium;
    _planDate = t?.planDate ?? widget.initialDate ?? Dates.today();
    _startTime = t?.startTimeOfDay;
    _reminderLead = t?.reminderLeadMinutes ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _duration.dispose();
    super.dispose();
  }

  String? _startTimeString() => _startTime == null
      ? null
      : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(taskRepositoryProvider);
    final duration = int.tryParse(_duration.text.trim());

    try {
      if (widget.isEditing) {
        final t = widget.task!;
        await repo.update(Task(
          id: t.id,
          title: _title.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          categoryId: _categoryId,
          templateId: t.templateId,
          priority: _priority,
          planDate: _planDate,
          startTime: _startTimeString(),
          durationMinutes: duration,
          reminderLeadMinutes: _reminderLead,
          // Preserve status/completion when editing.
          status: t.status,
          completedAt: t.completedAt,
          rescheduledToDate: t.rescheduledToDate,
          sortOrder: t.sortOrder,
        ));
      } else {
        await repo.create(
          title: _title.text.trim(),
          planDate: _planDate,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          categoryId: _categoryId,
          priority: _priority,
          startTime: _startTimeString(),
          durationMinutes: duration,
          reminderLeadMinutes: _reminderLead,
        );
      }
      // Saved. Leave without touching state again — this widget is gone, and
      // calling setState after pop() would be a no-op at best.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Network failures are absorbed by the outbox, so reaching here means the
      // *local* write failed. Say so instead of leaving the button spinning.
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSave(apiErrorMessage(l10n, e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editTask : l10n.newTask),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: l10n.titleLabel, prefixIcon: const Icon(Icons.title)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: l10n.notesOptional, prefixIcon: const Icon(Icons.notes)),
            ),
            const SizedBox(height: 16),
            Text(l10n.priority, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values)
                  ButtonSegment(value: p, label: Text(p.label(l10n))),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: InputDecoration(
                  labelText: l10n.category, prefixIcon: const Icon(Icons.label_outline)),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.categoryNone)),
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.dateLabel),
              subtitle: Text(DateLabels(l10n).long(_planDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _planDate,
                  firstDate: Dates.today().subtract(const Duration(days: 365)),
                  lastDate: Dates.today().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _planDate = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.startTimeLabel),
              subtitle: Text(_startTime == null ? l10n.anytime : _startTime!.format(context)),
              trailing: _startTime == null
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _startTime = null)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                );
                if (picked != null) setState(() => _startTime = picked);
              },
            ),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.durationLabel,
                prefixIcon: const Icon(Icons.hourglass_empty),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return l10n.durationMustBePositive;
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _reminderLead,
              decoration: InputDecoration(
                  labelText: l10n.reminderLabel,
                  prefixIcon: const Icon(Icons.notifications_outlined)),
              items: [
                for (final minutes in reminderLeadMinutesOptions)
                  DropdownMenuItem(
                      value: minutes, child: Text(reminderLeadLabel(l10n, minutes))),
              ],
              onChanged: (v) => setState(() => _reminderLead = v ?? 0),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(widget.isEditing ? l10n.saveChanges : l10n.addTask),
            ),
          ],
        ),
      ),
    );
  }
}
