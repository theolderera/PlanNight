import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../local/database.dart';
import '../local/mappers.dart';
import '../models/recurring_template.dart';
import '../sync/sync_engine.dart';

const _uuid = Uuid();

/// Offline-first recurring-template repository, plus the "generate a day's tasks
/// from templates" action used by the evening-planning flow.
class RecurringRepository {
  RecurringRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  Stream<List<RecurringTemplate>> watchAll() =>
      _db.watchTemplates().map((rows) => rows.map(templateFromRow).toList());

  Future<RecurringTemplate> create(RecurringTemplate template) async {
    final withId = _withId(template, _uuid.v4());
    await _db.upsertTemplate(templateToCompanion(withId));
    await _enqueue(withId.id, 'create', _payload(withId, includeId: true));
    _sync.syncNow();
    return withId;
  }

  Future<void> update(RecurringTemplate template) async {
    await _db.upsertTemplate(templateToCompanion(template));
    await _enqueue(template.id, 'update', _payload(template, includeId: false));
    _sync.syncNow();
  }

  Future<void> delete(RecurringTemplate template) async {
    await _db.upsertTemplate(
        templateToCompanion(template, deletedAt: DateTime.now()));
    await _enqueue(template.id, 'delete', const {});
    _sync.syncNow();
  }

  /// Materialise all matching templates into concrete tasks for [date]
  /// ('YYYY-MM-DD'). Runs server-side (idempotent) via the outbox; the created
  /// tasks flow back into the cache on sync.
  Future<void> generateForDate(String date) async {
    await _db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'planning',
      entityId: date,
      op: 'generate',
      payloadJson: Value(jsonEncode({'date': date})),
      createdAt: DateTime.now(),
    ));
    _sync.syncNow();
  }

  RecurringTemplate _withId(RecurringTemplate t, String id) => RecurringTemplate(
        id: id,
        title: t.title,
        notes: t.notes,
        categoryId: t.categoryId,
        priority: t.priority,
        startTime: t.startTime,
        durationMinutes: t.durationMinutes,
        reminderLeadMinutes: t.reminderLeadMinutes,
        recurrenceType: t.recurrenceType,
        daysOfWeek: t.daysOfWeek,
        active: t.active,
      );

  /// Re-queue every locally-cached template as an idempotent create so any that
  /// never reached the server get another chance. See TaskRepository.resyncAll.
  Future<int> resyncAll() async {
    final rows = await _db.allLiveTemplates();
    for (final r in rows) {
      final t = templateFromRow(r);
      await _enqueue(t.id, 'create', _payload(t, includeId: true));
    }
    return rows.length;
  }

  Future<void> _enqueue(String id, String op, Map<String, dynamic> payload) {
    return _db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'template',
      entityId: id,
      op: op,
      payloadJson: Value(jsonEncode(payload)),
      createdAt: DateTime.now(),
    ));
  }

  Map<String, dynamic> _payload(RecurringTemplate t, {required bool includeId}) => {
        if (includeId) 'id': t.id,
        'title': t.title,
        'notes': t.notes,
        'categoryId': t.categoryId,
        'priority': t.priority.api,
        'startTime': t.startTime,
        'durationMinutes': t.durationMinutes,
        'reminderLeadMinutes': t.reminderLeadMinutes,
        'recurrenceType': t.recurrenceType.api,
        'daysOfWeek': t.daysOfWeek,
        'active': t.active,
      };
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
  );
});
