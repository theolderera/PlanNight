// Pins down which outbox entries the sync engine is allowed to DISCARD.
//
// The rule: a queued write may only be dropped once we know the server has
// applied it (or has definitively rejected its content). Dropping on a 500 or a
// mid-flush 401 silently destroys the user's edit — that was a real bug, and
// these tests exist so it cannot come back.

import 'dart:typed_data' show Uint8List;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/data/local/database.dart';
import 'package:plannight/data/sync/sync_engine.dart';

/// A Dio adapter that answers every request with a fixed status code, so we can
/// drive `flushOutbox` through each failure mode without a server.
class _FixedStatusAdapter implements HttpClientAdapter {
  _FixedStatusAdapter(this.statusCode);

  /// null = a transport failure (no response at all), i.e. offline.
  final int? statusCode;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? _) async {
    requestCount++;
    if (statusCode == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'simulated offline',
      );
    }
    return ResponseBody.fromString('{}', statusCode!, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Queue one task write and try to flush it against a server that always
  /// answers [statusCode]. Returns how many entries survive in the outbox.
  Future<({int remaining, bool drained})> flushAgainst(
    int? statusCode, {
    String op = 'update',
  }) async {
    await db.enqueue(OutboxEntriesCompanion.insert(
      entityType: 'task',
      entityId: 'task-1',
      op: op,
      payloadJson: const Value('{"title":"Buy milk"}'),
      createdAt: DateTime.now(),
    ));

    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api'))
      ..httpClientAdapter = _FixedStatusAdapter(statusCode);
    final engine = SyncEngine(dio: dio, db: db);

    final drained = await engine.flushOutbox();
    return (remaining: (await db.pendingOutbox()).length, drained: drained);
  }

  group('an outbox entry is KEPT when the failure is transient', () {
    test('offline (no response at all)', () async {
      final r = await flushAgainst(null);
      expect(r.remaining, 1, reason: 'an offline write must survive to retry');
      expect(r.drained, isFalse);
    });

    test('500 — the server is broken, not our payload', () async {
      final r = await flushAgainst(500);
      expect(r.remaining, 1);
      expect(r.drained, isFalse);
    });

    test('503 — the server is unavailable', () async {
      final r = await flushAgainst(503);
      expect(r.remaining, 1);
    });

    test('401 — the session expired mid-flush; a refresh + retry will work', () async {
      final r = await flushAgainst(401);
      expect(r.remaining, 1);
    });

    test('429 — we are rate limited', () async {
      final r = await flushAgainst(429);
      expect(r.remaining, 1);
    });
  });

  group('an outbox entry is DROPPED when replaying it can never succeed', () {
    test('400 — the server rejected the content, so retrying would wedge the queue', () async {
      final r = await flushAgainst(400);
      expect(r.remaining, 0);
      expect(r.drained, isTrue);
    });

    test('422 — same: unprocessable content', () async {
      final r = await flushAgainst(422);
      expect(r.remaining, 0);
    });
  });

  group('an outbox entry is DROPPED when the server already applied it', () {
    test('409 on a create — the row exists, so the create landed', () async {
      final r = await flushAgainst(409, op: 'create');
      expect(r.remaining, 0);
      expect(r.drained, isTrue);
    });

    test('404 on an update — the row is gone, so the delete that removed it won', () async {
      final r = await flushAgainst(404, op: 'update');
      expect(r.remaining, 0);
    });

    test('404 on a delete — already deleted', () async {
      final r = await flushAgainst(404, op: 'delete');
      expect(r.remaining, 0);
    });

    test('409 on an update is NOT idempotently resolved — it is a content conflict', () async {
      // Only a *create* may treat 409 as "already applied".
      final r = await flushAgainst(409, op: 'update');
      expect(r.remaining, 0, reason: 'dropped as poisoned, not as already-applied');
    });
  });

  test('flushing stops at the first transient failure, preserving order', () async {
    // Two dependent writes: create the task, then complete it. If the create
    // fails transiently we must NOT skip ahead and replay the setStatus, which
    // would 404 against a task the server has never seen.
    for (final op in ['create', 'setStatus']) {
      await db.enqueue(OutboxEntriesCompanion.insert(
        entityType: 'task',
        entityId: 'task-1',
        op: op,
        payloadJson: const Value('{}'),
        createdAt: DateTime.now(),
      ));
    }

    final adapter = _FixedStatusAdapter(500);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api'))
      ..httpClientAdapter = adapter;

    final drained = await SyncEngine(dio: dio, db: db).flushOutbox();

    expect(drained, isFalse);
    expect((await db.pendingOutbox()).length, 2, reason: 'both writes kept');
    expect(adapter.requestCount, 1, reason: 'stopped after the first failure');
  });
}
