// Verifies the local stats computation matches the server's semantics:
// rescheduled excluded from the denominator, pct rounding, successful-day
// threshold, zero-filled ranges, and the streak grace rule for an in-progress
// today.

import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/core/date_utils.dart';
import 'package:plannight/data/models/task.dart';
import 'package:plannight/features/stats/stats_calc.dart';

int _seq = 0;
Task task(DateTime day, TaskStatus s) => Task(
      id: 'id${_seq++}',
      title: 't',
      priority: Priority.medium,
      planDate: day,
      status: s,
    );

void main() {
  final today = Dates.today();
  final iso = Dates.iso(today);

  group('computeSummary', () {
    test('empty input yields a zero-filled range, no active days', () {
      final s = computeSummary([], from: iso, to: iso, threshold: 80);
      expect(s.days, hasLength(1));
      expect(s.days.single.total, 0);
      expect(s.totalTasks, 0);
      expect(s.activeDays, 0);
      expect(s.completionPct, 0);
      expect(s.successfulDays, 0);
    });

    test('rescheduled tasks are excluded from the total', () {
      final tasks = [
        task(today, TaskStatus.completed),
        task(today, TaskStatus.completed),
        task(today, TaskStatus.planned),
        task(today, TaskStatus.rescheduled), // must not count
      ];
      final s = computeSummary(tasks, from: iso, to: iso, threshold: 80);
      final d = s.days.single;
      expect(d.total, 3, reason: 'rescheduled excluded');
      expect(d.completed, 2);
      expect(d.pending, 1);
      expect(d.completionPct, 67, reason: 'round(2/3*100)');
      expect(d.successful, isFalse, reason: '67% < 80% threshold');
    });

    test('a day meeting the threshold is successful', () {
      final tasks = [
        task(today, TaskStatus.completed),
        task(today, TaskStatus.completed),
        task(today, TaskStatus.completed),
        task(today, TaskStatus.completed),
        task(today, TaskStatus.skipped),
      ];
      final s = computeSummary(tasks, from: iso, to: iso, threshold: 80);
      expect(s.days.single.completionPct, 80);
      expect(s.days.single.successful, isTrue);
      expect(s.successfulDays, 1);
      expect(s.activeDays, 1);
    });

    test('range spans and zero-fills every day between from and to', () {
      final from = Dates.iso(Dates.addDays(today, -3));
      final s = computeSummary([task(today, TaskStatus.completed)],
          from: from, to: iso, threshold: 80);
      expect(s.days, hasLength(4)); // -3,-2,-1,0 inclusive
      expect(s.activeDays, 1);
    });
  });

  group('computeStreak', () {
    List<Task> completedDays(int count, {int endOffset = 0}) => [
          for (var i = 0; i < count; i++)
            task(Dates.addDays(today, endOffset - i), TaskStatus.completed),
        ];

    test('no data → zero streak', () {
      final s = computeStreak([], threshold: 80, today: today);
      expect(s.current, 0);
      expect(s.longest, 0);
    });

    test('counts consecutive successful days ending today', () {
      final s = computeStreak(completedDays(3), threshold: 80, today: today);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('grace: an empty (in-progress) today does not zero a prior run', () {
      // Successful yesterday and the day before, nothing yet today.
      final s = computeStreak(completedDays(2, endOffset: -1),
          threshold: 80, today: today);
      expect(s.current, 2, reason: 'counting starts from yesterday');
    });

    test('a failed day breaks the current streak', () {
      final tasks = [
        task(today, TaskStatus.completed),
        // yesterday: 0/1 completed → failed
        task(Dates.addDays(today, -1), TaskStatus.skipped),
        task(Dates.addDays(today, -2), TaskStatus.completed),
      ];
      final s = computeStreak(tasks, threshold: 80, today: today);
      expect(s.current, 1, reason: 'only today; yesterday failed');
      expect(s.longest, 1);
    });
  });
}
