import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/category.dart';
import '../models/recurring_template.dart';
import '../models/task.dart';
import 'database.dart';

// -----------------------------------------------------------------------------
// Conversions between drift rows/companions and the domain models the UI uses.
// Kept in one place so the shape of the cache and the shape of the API stay in
// lock-step.
// -----------------------------------------------------------------------------

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? _parseDt(Object? v) => v == null ? null : DateTime.parse(v as String);

// -----------------------------------------------------------------------------
// API JSON -> drift companion. Used by the sync engine when applying server
// rows. Unlike the model-based mappers below, these preserve the server's
// `updatedAt` and `deletedAt` verbatim, so soft-deletes and the sync watermark
// stay correct.
// -----------------------------------------------------------------------------

CategoriesCompanion categoryCompanionFromApi(Map<String, dynamic> j) =>
    CategoriesCompanion(
      id: Value(j['id'] as String),
      name: Value(j['name'] as String),
      colorHex: Value(j['color'] as String? ?? '#6C63FF'),
      updatedAt: Value(_parseDt(j['updatedAt']) ?? DateTime.now()),
      deletedAt: Value(_parseDt(j['deletedAt'])),
    );

TasksCompanion taskCompanionFromApi(Map<String, dynamic> j) => TasksCompanion(
      id: Value(j['id'] as String),
      title: Value(j['title'] as String),
      notes: Value(j['notes'] as String?),
      categoryId: Value(j['categoryId'] as String?),
      templateId: Value(j['templateId'] as String?),
      priority: Value(j['priority'] as String? ?? 'medium'),
      planDate: Value(j['planDate'] as String),
      startTime: Value(j['startTime'] as String?),
      durationMinutes: Value((j['durationMinutes'] as num?)?.toInt()),
      reminderLeadMinutes: Value((j['reminderLeadMinutes'] as num?)?.toInt()),
      status: Value(j['status'] as String? ?? 'planned'),
      completedAt: Value(_parseDt(j['completedAt'])),
      rescheduledToDate: Value(j['rescheduledToDate'] as String?),
      sortOrder: Value((j['sortOrder'] as num?)?.toInt() ?? 0),
      updatedAt: Value(_parseDt(j['updatedAt']) ?? DateTime.now()),
      deletedAt: Value(_parseDt(j['deletedAt'])),
    );

TemplatesCompanion templateCompanionFromApi(Map<String, dynamic> j) =>
    TemplatesCompanion(
      id: Value(j['id'] as String),
      title: Value(j['title'] as String),
      notes: Value(j['notes'] as String?),
      categoryId: Value(j['categoryId'] as String?),
      priority: Value(j['priority'] as String? ?? 'medium'),
      startTime: Value(j['startTime'] as String? ?? '08:00'),
      durationMinutes: Value((j['durationMinutes'] as num?)?.toInt()),
      reminderLeadMinutes: Value((j['reminderLeadMinutes'] as num?)?.toInt()),
      recurrenceType: Value(j['recurrenceType'] as String? ?? 'daily'),
      daysOfWeek: Value(jsonEncode(
          (j['daysOfWeek'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [])),
      active: Value(j['active'] as bool? ?? true),
      updatedAt: Value(_parseDt(j['updatedAt']) ?? DateTime.now()),
      deletedAt: Value(_parseDt(j['deletedAt'])),
    );

// ---- Category ----------------------------------------------------------------

Category categoryFromRow(CategoryRow r) => Category(
      id: r.id,
      name: r.name,
      colorHex: r.colorHex,
      deletedAt: r.deletedAt,
    );

CategoriesCompanion categoryToCompanion(Category c, {DateTime? updatedAt}) =>
    CategoriesCompanion(
      id: Value(c.id),
      name: Value(c.name),
      colorHex: Value(c.colorHex),
      updatedAt: Value(updatedAt ?? DateTime.now()),
      deletedAt: Value(c.deletedAt),
    );

// ---- Task --------------------------------------------------------------------

Task taskFromRow(TaskRow r) => Task(
      id: r.id,
      title: r.title,
      notes: r.notes,
      categoryId: r.categoryId,
      templateId: r.templateId,
      priority: Priority.fromApi(r.priority),
      planDate: DateTime.parse(r.planDate),
      startTime: r.startTime,
      durationMinutes: r.durationMinutes,
      reminderLeadMinutes: r.reminderLeadMinutes,
      status: TaskStatus.fromApi(r.status),
      completedAt: r.completedAt,
      rescheduledToDate:
          r.rescheduledToDate == null ? null : DateTime.parse(r.rescheduledToDate!),
      sortOrder: r.sortOrder,
    );

TasksCompanion taskToCompanion(Task t, {DateTime? updatedAt, DateTime? deletedAt}) =>
    TasksCompanion(
      id: Value(t.id),
      title: Value(t.title),
      notes: Value(t.notes),
      categoryId: Value(t.categoryId),
      templateId: Value(t.templateId),
      priority: Value(t.priority.api),
      planDate: Value(_dateStr(t.planDate)),
      startTime: Value(t.startTime),
      durationMinutes: Value(t.durationMinutes),
      reminderLeadMinutes: Value(t.reminderLeadMinutes),
      status: Value(t.status.api),
      completedAt: Value(t.completedAt),
      rescheduledToDate:
          Value(t.rescheduledToDate == null ? null : _dateStr(t.rescheduledToDate!)),
      sortOrder: Value(t.sortOrder),
      updatedAt: Value(updatedAt ?? DateTime.now()),
      deletedAt: Value(deletedAt),
    );

// ---- Template ----------------------------------------------------------------

RecurringTemplate templateFromRow(TemplateRow r) => RecurringTemplate(
      id: r.id,
      title: r.title,
      notes: r.notes,
      categoryId: r.categoryId,
      priority: Priority.fromApi(r.priority),
      startTime: r.startTime,
      durationMinutes: r.durationMinutes,
      reminderLeadMinutes: r.reminderLeadMinutes,
      recurrenceType: RecurrenceType.fromApi(r.recurrenceType),
      daysOfWeek: (jsonDecode(r.daysOfWeek) as List).map((e) => e as int).toList(),
      active: r.active,
    );

TemplatesCompanion templateToCompanion(RecurringTemplate t,
        {DateTime? updatedAt, DateTime? deletedAt}) =>
    TemplatesCompanion(
      id: Value(t.id),
      title: Value(t.title),
      notes: Value(t.notes),
      categoryId: Value(t.categoryId),
      priority: Value(t.priority.api),
      startTime: Value(t.startTime),
      durationMinutes: Value(t.durationMinutes),
      reminderLeadMinutes: Value(t.reminderLeadMinutes),
      recurrenceType: Value(t.recurrenceType.api),
      daysOfWeek: Value(jsonEncode(t.daysOfWeek)),
      active: Value(t.active),
      updatedAt: Value(updatedAt ?? DateTime.now()),
      deletedAt: Value(deletedAt),
    );
