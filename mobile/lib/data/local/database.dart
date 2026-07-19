import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// -----------------------------------------------------------------------------
// Local SQLite cache (via drift).
//
// The three data tables mirror the server rows and are the source of truth the
// UI reads from (reactively), so the app works fully offline. Writes are applied
// here optimistically and also appended to [OutboxEntries]; the SyncEngine
// replays those to the backend when online, and pulls server deltas back in.
//
// Dates/times are stored as the same strings the API uses ('YYYY-MM-DD',
// 'HH:MM') to avoid any timezone round-tripping.
// -----------------------------------------------------------------------------

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#6C63FF'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get templateId => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get planDate => text()(); // 'YYYY-MM-DD'
  TextColumn get startTime => text().nullable()(); // 'HH:MM'
  IntColumn get durationMinutes => integer().nullable()();
  IntColumn get reminderLeadMinutes => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get rescheduledToDate => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TemplateRow')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get startTime => text()(); // 'HH:MM'
  IntColumn get durationMinutes => integer().nullable()();
  IntColumn get reminderLeadMinutes => integer().nullable()();
  TextColumn get recurrenceType => text()(); // daily|weekly|custom
  TextColumn get daysOfWeek => text().withDefault(const Constant('[]'))(); // JSON array
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue of local mutations awaiting replay to the backend.
@DataClassName('OutboxRow')
class OutboxEntries extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entityType => text()(); // task|category|template|user
  TextColumn get entityId => text()();
  TextColumn get op => text()(); // create|update|delete|setStatus|reschedule|generate
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Single-row table holding the last sync watermark (server timestamp).
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get lastServerTime => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Categories, Tasks, Templates, OutboxEntries, SyncMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'plannight'));

  @override
  int get schemaVersion => 1;

  // --- Reactive reads (UI watches these) ------------------------------------

  /// Live list of a single day's tasks, ordered chronologically.
  Stream<List<TaskRow>> watchTasksForDay(String date) {
    return (select(tasks)
          ..where((t) => t.planDate.equals(date) & t.deletedAt.isNull())
          ..orderBy([
            // Untimed tasks sort last; then by manual order.
            (t) => OrderingTerm(expression: t.startTime, nulls: NullsOrder.last),
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  /// Live list of tasks within an inclusive date range (history/calendar).
  Stream<List<TaskRow>> watchTasksInRange(String from, String to) {
    return (select(tasks)
          ..where((t) =>
              t.planDate.isBiggerOrEqualValue(from) &
              t.planDate.isSmallerOrEqualValue(to) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.planDate)]))
        .watch();
  }

  Stream<List<CategoryRow>> watchCategories() {
    return (select(categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .watch();
  }

  Stream<List<TemplateRow>> watchTemplates() {
    return (select(templates)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  Future<TaskRow?> findTask(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // --- One-shot reads of all live rows (used by the repair re-sync) ---------

  Future<List<TaskRow>> allLiveTasks() =>
      (select(tasks)..where((t) => t.deletedAt.isNull())).get();

  Future<List<CategoryRow>> allLiveCategories() =>
      (select(categories)..where((c) => c.deletedAt.isNull())).get();

  Future<List<TemplateRow>> allLiveTemplates() =>
      (select(templates)..where((t) => t.deletedAt.isNull())).get();

  // --- Upserts used by the sync engine when pulling server rows -------------

  Future<void> upsertTask(TasksCompanion row) =>
      into(tasks).insertOnConflictUpdate(row);

  Future<void> upsertCategory(CategoriesCompanion row) =>
      into(categories).insertOnConflictUpdate(row);

  Future<void> upsertTemplate(TemplatesCompanion row) =>
      into(templates).insertOnConflictUpdate(row);

  // --- Outbox ----------------------------------------------------------------

  Future<void> enqueue(OutboxEntriesCompanion entry) =>
      into(outboxEntries).insert(entry);

  Future<List<OutboxRow>> pendingOutbox() =>
      (select(outboxEntries)..orderBy([(o) => OrderingTerm(expression: o.seq)]))
          .get();

  Stream<int> watchPendingCount() {
    final count = outboxEntries.seq.count();
    final q = selectOnly(outboxEntries)..addColumns([count]);
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  Future<void> removeOutbox(int seq) =>
      (delete(outboxEntries)..where((o) => o.seq.equals(seq))).go();

  // --- Sync watermark --------------------------------------------------------

  Future<String?> lastServerTime() async {
    final row =
        await (select(syncMeta)..where((m) => m.id.equals(1))).getSingleOrNull();
    return row?.lastServerTime;
  }

  Future<void> setLastServerTime(String value) async {
    await into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(id: const Value(1), lastServerTime: Value(value)),
    );
  }

  /// Wipe all cached data (used on logout).
  Future<void> clearAll() async {
    await batch((b) {
      b.deleteAll(tasks);
      b.deleteAll(categories);
      b.deleteAll(templates);
      b.deleteAll(outboxEntries);
      b.deleteAll(syncMeta);
    });
  }
}
