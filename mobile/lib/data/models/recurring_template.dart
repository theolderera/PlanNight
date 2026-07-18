import 'task.dart' show Priority;

/// How a recurring template repeats.
enum RecurrenceType {
  daily,
  weekly,
  custom;

  static RecurrenceType fromApi(String? v) => switch (v) {
        'weekly' => RecurrenceType.weekly,
        'custom' => RecurrenceType.custom,
        _ => RecurrenceType.daily,
      };

  String get api => name;
}

/// A blueprint for a repeating task, expanded into concrete tasks per day.
class RecurringTemplate {
  const RecurringTemplate({
    required this.id,
    required this.title,
    this.notes,
    this.categoryId,
    required this.priority,
    required this.startTime,
    this.durationMinutes,
    this.reminderLeadMinutes,
    required this.recurrenceType,
    required this.daysOfWeek,
    required this.active,
  });

  final String id;
  final String title;
  final String? notes;
  final String? categoryId;
  final Priority priority;

  /// Wall-clock 'HH:MM' the generated tasks start at.
  final String startTime;
  final int? durationMinutes;
  final int? reminderLeadMinutes;

  final RecurrenceType recurrenceType;

  /// Days it applies to: 0=Sunday .. 6=Saturday. Empty for daily.
  final List<int> daysOfWeek;
  final bool active;

  factory RecurringTemplate.fromJson(Map<String, dynamic> json) =>
      RecurringTemplate(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String?,
        categoryId: json['categoryId'] as String?,
        priority: Priority.fromApi(json['priority'] as String?),
        startTime: (json['startTime'] as String?) ?? '08:00',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt(),
        recurrenceType: RecurrenceType.fromApi(json['recurrenceType'] as String?),
        daysOfWeek: (json['daysOfWeek'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        active: json['active'] as bool? ?? true,
      );
}
