import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../local/database.dart';
import '../local/mappers.dart';
import '../models/task.dart';
import '../sync/sync_engine.dart';

const _uuid = Uuid();

/// Offline-first task repository.
///
/// Reads come straight from the drift cache (reactive, work offline). Writes are
/// applied to the cache immediately (optimistic UI), queued in the outbox, and
/// then a background sync is kicked off — so the UI never waits on the network.
class TaskRepository {
  TaskRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  // ---- Reads ----------------------------------------------------------------

  Stream<List<Task>> watchDay(String date) =>
      _db.watchTasksForDay(date).map((rows) => rows.map(taskFromRow).toList());

  Stream<List<Task>> watchRange(String from, String to) =>
      _db.watchTasksInRange(from, to).map((rows) => rows.map(taskFromRow).toList());

  // ---- Writes ---------------------------------------------------------------

  /// Create a task with a client-generated id (so it survives sync unchanged).
  Future<Task> create({
    required String title,
    required DateTime planDate,
    String? notes,
    String? categoryId,
    Priority priority = Priority.medium,
    String? startTime,
    int? durationMinutes,
    int? reminderLeadMinutes,
    int sortOrder = 0,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      categoryId: categoryId,
      priority: priority,
      planDate: planDate,
      startTime: startTime,
      durationMinutes: durationMinutes,
      reminderLeadMinutes: reminderLeadMinutes,
      status: TaskStatus.planned,
      sortOrder: sortOrder,
    );
    await _db.upsertTask(taskToCompanion(task));
    await _enqueue(task.id, 'create', _writePayload(task, includeId: true));
    _sync.syncNow();
    return task;
  }

  /// Replace a task's editable fields (optimistic full-object update).
  Future<void> update(Task task) async {
    await _db.upsertTask(taskToCompanion(task));
    await _enqueue(task.id, 'update', _writePayload(task, includeId: false));
    _sync.syncNow();
  }

  /// Mark completed/skipped/planned, keeping completedAt consistent.
  Future<void> setStatus(Task task, TaskStatus status) async {
    final updated = Task(
      id: task.id,
      title: task.title,
      notes: task.notes,
      categoryId: task.categoryId,
      templateId: task.templateId,
      priority: task.priority,
      planDate: task.planDate,
      startTime: task.startTime,
      durationMinutes: task.durationMinutes,
      reminderLeadMinutes: task.reminderLeadMinutes,
      status: status,
      completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      sortOrder: task.sortOrder,
    );
    await _db.upsertTask(taskToCompanion(updated));
    await _enqueue(task.id, 'setStatus', {'status': status.api});
    _sync.syncNow();
  }

  /// Soft-delete locally and queue the server delete.
  Future<void> delete(Task task) async {
    await _db.upsertTask(taskToCompanion(task, deletedAt: DateTime.now()));
    await _enqueue(task.id, 'delete', const {});
    _sync.syncNow();
  }

  /// Move to another day: mark the original rescheduled locally; the server
  /// creates the copy, which arrives on the next pull.
  Future<void> reschedule(Task task, DateTime date) async {
    final marked = Task(
      id: task.id,
      title: task.title,
      notes: task.notes,
      categoryId: task.categoryId,
      templateId: task.templateId,
      priority: task.priority,
      planDate: task.planDate,
      startTime: task.startTime,
      durationMinutes: task.durationMinutes,
      reminderLeadMinutes: task.reminderLeadMinutes,
      status: TaskStatus.rescheduled,
      rescheduledToDate: date,
      sortOrder: task.sortOrder,
    );
    await _db.upsertTask(taskToCompanion(marked));
    await _enqueue(task.id, 'reschedule', {'date': _dateStr(date)});
    _sync.syncNow();
  }

  // ---- Helpers --------------------------------------------------------------

  Future<void> _enqueue(String id, String op, Map<String, dynamic> payload) {
    return _db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'task',
      entityId: id,
      op: op,
      payloadJson: Value(jsonEncode(payload)),
      createdAt: DateTime.now(),
    ));
  }

  Map<String, dynamic> _writePayload(Task t, {required bool includeId}) => {
        if (includeId) 'id': t.id,
        'title': t.title,
        'notes': t.notes,
        'categoryId': t.categoryId,
        'priority': t.priority.api,
        'planDate': _dateStr(t.planDate),
        'startTime': t.startTime,
        'durationMinutes': t.durationMinutes,
        'reminderLeadMinutes': t.reminderLeadMinutes,
        'sortOrder': t.sortOrder,
      };

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
  );
});
