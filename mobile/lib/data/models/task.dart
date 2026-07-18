import 'package:flutter/material.dart';

import '../../core/l10n.dart';

/// Task priority. Kept as an enum for type-safety, mapped to/from API strings.
enum Priority {
  high,
  medium,
  low;

  static Priority fromApi(String? v) => switch (v) {
        'high' => Priority.high,
        'low' => Priority.low,
        _ => Priority.medium,
      };

  /// The wire value. Never shown to a user — see [label].
  String get api => name;

  /// The translated name, for display.
  String label(AppLocalizations l10n) => switch (this) {
        Priority.high => l10n.priorityHigh,
        Priority.medium => l10n.priorityMedium,
        Priority.low => l10n.priorityLow,
      };
}

/// Lifecycle status of a task.
enum TaskStatus {
  planned,
  completed,
  skipped,
  rescheduled;

  static TaskStatus fromApi(String? v) => switch (v) {
        'completed' => TaskStatus.completed,
        'skipped' => TaskStatus.skipped,
        'rescheduled' => TaskStatus.rescheduled,
        _ => TaskStatus.planned,
      };

  String get api => name;
}

/// A concrete, checkable task belonging to one calendar day.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes,
    this.categoryId,
    this.templateId,
    required this.priority,
    required this.planDate,
    this.startTime,
    this.durationMinutes,
    this.reminderLeadMinutes,
    required this.status,
    this.completedAt,
    this.rescheduledToDate,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String? notes;
  final String? categoryId;
  final String? templateId;
  final Priority priority;

  /// Local calendar day (time component is meaningless; treat as date-only).
  final DateTime planDate;

  /// Wall-clock start as 'HH:MM', or null for an "anytime" task.
  final String? startTime;
  final int? durationMinutes;
  final int? reminderLeadMinutes;

  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime? rescheduledToDate;
  final int sortOrder;

  bool get isDone => status == TaskStatus.completed;

  /// Parse 'HH:MM' into a [TimeOfDay] for pickers/display, or null.
  TimeOfDay? get startTimeOfDay {
    final t = startTime;
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String?,
        categoryId: json['categoryId'] as String?,
        templateId: json['templateId'] as String?,
        priority: Priority.fromApi(json['priority'] as String?),
        planDate: DateTime.parse(json['planDate'] as String),
        startTime: json['startTime'] as String?,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt(),
        status: TaskStatus.fromApi(json['status'] as String?),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        rescheduledToDate: json['rescheduledToDate'] == null
            ? null
            : DateTime.parse(json['rescheduledToDate'] as String),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
