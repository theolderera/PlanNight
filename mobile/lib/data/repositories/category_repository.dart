import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../local/database.dart';
import '../local/mappers.dart';
import '../models/category.dart';
import '../sync/sync_engine.dart';

const _uuid = Uuid();

/// Offline-first category repository (same optimistic-write + outbox pattern as
/// [TaskRepository]).
class CategoryRepository {
  CategoryRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  Stream<List<Category>> watchAll() =>
      _db.watchCategories().map((rows) => rows.map(categoryFromRow).toList());

  Future<Category> create({required String name, required String colorHex}) async {
    final category = Category(id: _uuid.v4(), name: name, colorHex: colorHex);
    await _db.upsertCategory(categoryToCompanion(category));
    await _enqueue(category.id, 'create',
        {'id': category.id, 'name': name, 'color': colorHex});
    _sync.syncNow();
    return category;
  }

  Future<void> update(Category category) async {
    await _db.upsertCategory(categoryToCompanion(category));
    await _enqueue(category.id, 'update',
        {'name': category.name, 'color': category.colorHex});
    _sync.syncNow();
  }

  Future<void> delete(Category category) async {
    await _db.upsertCategory(
        categoryToCompanion(category, updatedAt: DateTime.now())
            .copyWith(deletedAt: Value(DateTime.now())));
    await _enqueue(category.id, 'delete', const {});
    _sync.syncNow();
  }

  /// Re-queue every locally-cached category as an idempotent create so any that
  /// never reached the server get another chance. See TaskRepository.resyncAll.
  Future<int> resyncAll() async {
    final rows = await _db.allLiveCategories();
    for (final r in rows) {
      final c = categoryFromRow(r);
      await _enqueue(c.id, 'create', {'id': c.id, 'name': c.name, 'color': c.colorHex});
    }
    return rows.length;
  }

  Future<void> _enqueue(String id, String op, Map<String, dynamic> payload) {
    return _db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'category',
      entityId: id,
      op: op,
      payloadJson: Value(jsonEncode(payload)),
      createdAt: DateTime.now(),
    ));
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(databaseProvider),
    ref.watch(syncEngineProvider),
  );
});
