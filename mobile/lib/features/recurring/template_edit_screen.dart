import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/reminder_options.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/api/api_error.dart';
import '../../data/models/category.dart';
import '../../data/models/recurring_template.dart';
import '../../data/models/task.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/ui_providers.dart';

/// Create or edit a recurring template.
class TemplateEditScreen extends ConsumerStatefulWidget {
  const TemplateEditScreen({super.key, this.template});

  final RecurringTemplate? template;
  bool get isEditing => template != null;

  @override
  ConsumerState<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends ConsumerState<TemplateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;

  String? _categoryId;
  Priority _priority = Priority.medium;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  int _reminderLead = 0;
  bool _everyDay = true;
  final Set<int> _days = {}; // API numbering: 0 = Sun .. 6 = Sat
  bool _saving = false;

  static const _priorityOrder = [Priority.low, Priority.medium, Priority.high];

  /// Weekday chips in display order (Monday first), paired with the API value.
  static const _weekOrder = <(int apiValue, int dartWeekday)>[
    (1, DateTime.monday),
    (2, DateTime.tuesday),
    (3, DateTime.wednesday),
    (4, DateTime.thursday),
    (5, DateTime.friday),
    (6, DateTime.saturday),
    (0, DateTime.sunday),
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _categoryId = t?.categoryId;
    _priority = t?.priority ?? Priority.medium;
    if (t != null) {
      final parts = t.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _reminderLead = t.reminderLeadMinutes ?? 0;
      _everyDay = t.recurrenceType == RecurrenceType.daily;
      _days.addAll(t.daysOfWeek);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (!_everyDay && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pickAtLeastOneDay)),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(recurringRepositoryProvider);
    final startTime =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';

    final template = RecurringTemplate(
      id: widget.template?.id ?? '',
      title: _title.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      categoryId: _categoryId,
      priority: _priority,
      startTime: startTime,
      durationMinutes: widget.template?.durationMinutes,
      reminderLeadMinutes: _reminderLead,
      recurrenceType: _everyDay ? RecurrenceType.daily : RecurrenceType.custom,
      daysOfWeek: _everyDay ? const [] : (_days.toList()..sort()),
      active: widget.template?.active ?? true,
    );

    try {
      if (widget.isEditing) {
        await repo.update(template);
      } else {
        await repo.create(template);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSave(apiErrorMessage(l10n, e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = DateLabels(l10n);
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEditing ? l10n.editTemplate : l10n.newTemplate,
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
              maxLines: 3,
              style: TextStyle(fontWeight: FontWeight.w500, color: c.ink),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.startTimeLabel),
            FieldTile(
              leading: Icon(Icons.schedule_rounded, size: 18, color: c.accent),
              trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
              child: Text(_startTime.format(context), style: context.mono(size: 15)),
            ),
            const SizedBox(height: 18),

            FieldLabel(l10n.category),
            _TemplateCategoryChips(
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

            FieldLabel(l10n.repeats),
            PillSegment(
              options: [l10n.everyDay, l10n.specificDays],
              selected: _everyDay ? 0 : 1,
              onSelect: (i) => setState(() => _everyDay = i == 0),
            ),
            if (!_everyDay) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (apiValue, dartWeekday) in _weekOrder)
                    _DayChip(
                      label: dates.weekdayShort(dartWeekday),
                      selected: _days.contains(apiValue),
                      onTap: () => setState(
                          () => _days.contains(apiValue) ? _days.remove(apiValue) : _days.add(apiValue)),
                    ),
                ],
              ),
            ],
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
              label: Text(widget.isEditing ? l10n.saveChanges : l10n.createTemplate),
            ),
          ],
        ),
      ),
    );
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

class _TemplateCategoryChips extends StatelessWidget {
  const _TemplateCategoryChips({required this.categories, required this.selectedId, required this.onSelect});
  final List<Category> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget chip({required String label, required bool selected, required VoidCallback onTap, Color? dot}) {
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
                      fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: selected ? c.ink : c.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(label: l10n.categoryNone, selected: selectedId == null, onTap: () => onSelect(null)),
        for (final cat in categories)
          chip(label: cat.name, dot: cat.color, selected: selectedId == cat.id, onTap: () => onSelect(cat.id)),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? null : [BoxShadow(color: c.shadow, blurRadius: 6, offset: const Offset(0, 1), spreadRadius: -3)],
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: AppFonts.sans, fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : c.textSecondary)),
      ),
    );
  }
}
