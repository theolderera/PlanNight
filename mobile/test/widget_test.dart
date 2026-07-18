// Foundation unit tests: model JSON parsing. These run headlessly (no device,
// no backend) and guard the DTO mapping the whole app relies on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/data/models/category.dart';
import 'package:plannight/data/models/task.dart';

void main() {
  test('Task.fromJson maps fields, priority, status and time', () {
    final task = Task.fromJson({
      'id': 't1',
      'title': 'Morning run',
      'notes': null,
      'categoryId': 'c1',
      'templateId': null,
      'priority': 'high',
      'planDate': '2026-07-08',
      'startTime': '07:30',
      'durationMinutes': 30,
      'reminderLeadMinutes': null,
      'status': 'completed',
      'completedAt': '2026-07-08T02:30:00.000Z',
      'rescheduledToDate': null,
      'sortOrder': 0,
    });

    expect(task.title, 'Morning run');
    expect(task.priority, Priority.high);
    expect(task.status, TaskStatus.completed);
    expect(task.isDone, isTrue);
    expect(task.startTimeOfDay, const TimeOfDay(hour: 7, minute: 30));
    expect(task.planDate.year, 2026);
    expect(task.planDate.month, 7);
    expect(task.planDate.day, 8);
  });

  test('Task priority/status fall back to sensible defaults', () {
    final task = Task.fromJson({
      'id': 't2',
      'title': 'Anytime task',
      'priority': 'nonsense',
      'planDate': '2026-07-08',
      'status': 'weird',
    });
    expect(task.priority, Priority.medium);
    expect(task.status, TaskStatus.planned);
    expect(task.startTimeOfDay, isNull);
  });

  test('Category parses hex colour into a Color', () {
    final cat = Category.fromJson({'id': 'c1', 'name': 'Health', 'color': '#22C55E'});
    expect(cat.color, const Color(0xFF22C55E));
    expect(cat.isDeleted, isFalse);
  });
}
