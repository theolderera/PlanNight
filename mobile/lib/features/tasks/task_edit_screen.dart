import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/reminder_options.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/api/api_error.dart';
import '../../data/models/category.dart';
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

  // Segment order shown to the user: low → medium → high.
  static const _priorityOrder = [Priority.low, Priority.medium, Priority.high];

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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
    final c = context.colors;
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEditing ? l10n.editTask : l10n.newTask,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FieldLabel(l10n.titleLabel),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.title_rounded)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.notesOptional),
            TextFormField(
              controller: _notes,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontWeight: FontWeight.w500, color: c.ink),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(l10n.startTimeLabel),
                      FieldTile(
                        leading: Icon(Icons.schedule_rounded, size: 18, color: c.accent),
                        onTap: _pickTime,
                        trailing: _startTime != null
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 16, color: c.textMuted),
                                onPressed: () => setState(() => _startTime = null),
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                        child: Text(
                          _startTime == null ? l10n.anytime : _startTime!.format(context),
                          style: _startTime == null
                              ? TextStyle(fontWeight: FontWeight.w500, color: c.textMuted)
                              : context.mono(size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(l10n.durationLabelShort),
                      TextFormField(
                        controller: _duration,
                        keyboardType: TextInputType.number,
                        style: context.mono(size: 15),
                        decoration: InputDecoration(
                          hintText: '—',
                          suffixText: l10n.minutesSuffix,
                          suffixStyle: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return l10n.durationMustBePositive;
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.dateLabel),
            FieldTile(
              leading: Icon(Icons.calendar_today_rounded, size: 18, color: c.accent),
              trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
              onTap: _pickDate,
              child: Text(DateLabels(l10n).long(_planDate),
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.category),
            _CategoryChips(
              categories: categories,
              selectedId: _categoryId,
              onSelect: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.priority),
            PillSegment(
              options: [for (final p in _priorityOrder) p.label(l10n)],
              selected: _priorityOrder.indexOf(_priority),
              onSelect: (i) => setState(() => _priority = _priorityOrder[i]),
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.reminderLabel),
            FieldTile(
              leading: Icon(Icons.notifications_outlined, size: 18, color: c.accent),
              trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
              onTap: _pickReminder,
              child: Text(reminderLeadLabel(l10n, _reminderLead),
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(widget.isEditing ? l10n.saveChanges : l10n.addTask),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _planDate,
      firstDate: Dates.today().subtract(const Duration(days: 365)),
      lastDate: Dates.today().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _planDate = picked);
  }

  Future<void> _pickReminder() async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in reminderLeadMinutesOptions)
              ListTile(
                title: Text(reminderLeadLabel(l10n, m),
                    style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: m == _reminderLead ? FontWeight.w700 : FontWeight.w500,
                        color: m == _reminderLead ? context.colors.accent : context.colors.ink)),
                trailing: m == _reminderLead ? Icon(Icons.check_rounded, color: context.colors.accent) : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _reminderLead = picked);
  }
}

/// Horizontal, wrapping category chips including a "None" option.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories, required this.selectedId, required this.onSelect});
  final List<Category> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: l10n.categoryNone,
          selected: selectedId == null,
          onTap: () => onSelect(null),
        ),
        for (final cat in categories)
          _Chip(
            label: cat.name,
            dot: cat.color,
            selected: selectedId == cat.id,
            onTap: () => onSelect(cat.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.dot});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.accentTint : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent : Colors.transparent, width: 1.5),
          boxShadow: selected ? null : [BoxShadow(color: c.shadow, blurRadius: 6, offset: const Offset(0, 1), spreadRadius: -3)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? c.ink : c.textSecondary)),
          ],
        ),
      ),
    );
  }
}
