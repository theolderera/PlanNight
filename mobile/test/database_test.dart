// Exercises the drift cache against a real in-memory SQLite database: upserts,
// reactive day queries, ordering, soft-delete hiding, and the outbox queue.

// Hide drift's `isNull` (a SQL expression helper) so it doesn't clash with the
// matcher of the same name used in expect(...).
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  TasksCompanion task(String id, String date, {String? time, DateTime? deleted}) =>
      TasksCompanion.insert(
        id: id,
        title: 'Task $id',
        planDate: date,
        startTime: Value(time),
        updatedAt: DateTime.now(),
        deletedAt: Value(deleted),
      );

  test('tasks for a day are returned in chronological order, untimed last', () async {
    await db.upsertTask(task('a', '2026-07-08', time: '09:00'));
    await db.upsertTask(task('b', '2026-07-08', time: '07:30'));
    await db.upsertTask(task('c', '2026-07-08')); // untimed
    await db.upsertTask(task('x', '2026-07-09', time: '06:00')); // other day

    final rows = await db.watchTasksForDay('2026-07-08').first;
    expect(rows.map((r) => r.id).toList(), ['b', 'a', 'c']);
  });

  test('soft-deleted tasks are hidden from day queries', () async {
    await db.upsertTask(task('a', '2026-07-08', time: '09:00'));
    await db.upsertTask(task('b', '2026-07-08', time: '10:00', deleted: DateTime.now()));

    final rows = await db.watchTasksForDay('2026-07-08').first;
    expect(rows.map((r) => r.id), ['a']);
  });

  test('upsert overwrites an existing row (last-write-wins on pull)', () async {
    await db.upsertTask(task('a', '2026-07-08', time: '09:00'));
    await db.upsertTask(task('a', '2026-07-08', time: '11:00'));

    final row = await db.findTask('a');
    expect(row!.startTime, '11:00');
  });

  test('outbox enqueues, lists in order, and removes', () async {
    await db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'task', entityId: 'a', op: 'create', createdAt: DateTime.now()));
    await db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'task', entityId: 'a', op: 'setStatus', createdAt: DateTime.now()));

    var pending = await db.pendingOutbox();
    expect(pending.map((o) => o.op), ['create', 'setStatus']);

    await db.removeOutbox(pending.first.seq);
    pending = await db.pendingOutbox();
    expect(pending.map((o) => o.op), ['setStatus']);
  });

  test('sync watermark round-trips', () async {
    expect(await db.lastServerTime(), isNull);
    await db.setLastServerTime('2026-07-08T00:00:00.000Z');
    expect(await db.lastServerTime(), '2026-07-08T00:00:00.000Z');
  });
}
