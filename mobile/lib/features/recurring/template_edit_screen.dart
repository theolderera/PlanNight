import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/reminder_options.dart';
import '../../data/api/api_error.dart';
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
  // API numbering: 0 = Sunday .. 6 = Saturday.
  final Set<int> _days = {};
  bool _saving = false;

  /// Weekday chips in display order (Monday first), paired with the API's value
  /// for that day. Dart's `DateTime.sunday` is 7, the API's Sunday is 0.
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
    final dates = DateLabels(l10n);
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? l10n.editTemplate : l10n.newTemplate)),
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
              maxLines: 3,
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
              leading: const Icon(Icons.schedule),
              title: Text(l10n.startTimeLabel),
              subtitle: Text(_startTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
            ),
            const SizedBox(height: 8),
            Text(l10n.repeats, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.everyDay)),
                ButtonSegment(value: false, label: Text(l10n.specificDays)),
              ],
              selected: {_everyDay},
              onSelectionChanged: (s) => setState(() => _everyDay = s.first),
            ),
            if (!_everyDay) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final (apiValue, dartWeekday) in _weekOrder)
                    FilterChip(
                      label: Text(dates.weekdayShort(dartWeekday)),
                      selected: _days.contains(apiValue),
                      onSelected: (sel) => setState(
                          () => sel ? _days.add(apiValue) : _days.remove(apiValue)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
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
              label: Text(widget.isEditing ? l10n.saveChanges : l10n.createTemplate),
            ),
          ],
        ),
      ),
    );
  }
}
