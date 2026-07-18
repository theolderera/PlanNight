import 'dart:convert';

import 'package:dio/dio.dart';

import '../local/database.dart';
import '../local/mappers.dart';

/// Thrown internally to stop a pull when the network is unreachable, so the
/// caller can silently give up and retry on the next connectivity event.
class _OfflineException implements Exception {}

/// Coordinates offline-first sync between the drift cache and the REST API.
///
///   * [flushOutbox] replays locally-queued mutations to the server.
///   * [pull] fetches server changes since the last watermark into the cache.
///   * [syncNow] does both (flush first so our writes land before we pull).
///
/// last-write-wins: pull upserts server rows over local copies; because we flush
/// before pulling, the server already has our latest edits when we read back.
class SyncEngine {
  SyncEngine({required this.dio, required this.db});

  final Dio dio;
  final AppDatabase db;

  /// Called with the server's copy of the user row whenever a pull returns one
  /// (i.e. the settings changed since our last sync — possibly on another
  /// device). The app wires this to the auth controller so theme/language/
  /// threshold changes actually land in the UI instead of being discarded.
  void Function(Map<String, dynamic> user)? onUserPulled;

  bool _running = false;

  /// Flush queued writes, then pull deltas. Safe to call often; it self-guards
  /// against overlapping runs. Swallows offline errors (they retry later).
  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    try {
      final flushed = await flushOutbox();
      if (flushed) await pull();
    } on _OfflineException {
      // Offline — try again on next connectivity/foreground event.
    } finally {
      _running = false;
    }
  }

  // --- Outbox replay ---------------------------------------------------------

  /// Replays every pending outbox entry in order. Returns true if the queue was
  /// fully drained (so it's safe to pull), false if we stopped early and must
  /// retry the remaining entries later.
  ///
  /// Ordering matters: entries can depend on each other (create a task, then
  /// complete it). So the moment one entry cannot be applied *yet*, we stop
  /// rather than skipping ahead — otherwise the later entry would 404.
  Future<bool> flushOutbox() async {
    final pending = await db.pendingOutbox();
    for (final entry in pending) {
      try {
        await _replay(entry);
        await db.removeOutbox(entry.seq);
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        // No response at all: offline / timeout / DNS. Keep everything.
        if (e.response == null) return false;

        // The server saw it and it's already applied — drop it and carry on.
        if (_isIdempotentlyResolved(entry.op, status)) {
          await db.removeOutbox(entry.seq);
          continue;
        }

        // Transient: the server is unwell (5xx), we're rate-limited (429), or
        // the session expired mid-flush (401/403 — the api client is refreshing
        // the token and a retry will succeed). Keep the entry and stop here.
        if (_isTransient(status)) return false;

        // Genuinely poisoned: the server rejected the *content* (400/422/...).
        // Replaying it forever would wedge the queue behind an entry that can
        // never succeed, so drop this one and continue with the rest.
        await db.removeOutbox(entry.seq);
      }
    }
    return true;
  }

  /// A create that 409s (already exists) or an update/delete whose target is
  /// already gone (404) is effectively already applied on the server.
  bool _isIdempotentlyResolved(String op, int? status) {
    if (op == 'create' && status == 409) return true;
    if ((op == 'update' || op == 'delete' || op == 'setStatus') && status == 404) {
      return true;
    }
    return false;
  }

  /// Failures worth retrying rather than discarding the user's write.
  ///
  /// Dropping these was a silent data-loss bug: a single 500 or an expired
  /// access token would delete the queued change and the user's edit would
  /// simply vanish on the next sync.
  bool _isTransient(int? status) {
    if (status == null) return true;
    if (status == 401 || status == 403) return true; // auth: retry after refresh
    if (status == 408 || status == 429) return true; // timeout / rate limited
    return status >= 500; // server-side fault
  }

  Future<void> _replay(OutboxRow e) async {
    final payload = jsonDecode(e.payloadJson) as Map<String, dynamic>;
    switch (e.entityType) {
      case 'task':
        switch (e.op) {
          case 'create':
            await dio.post('/tasks', data: payload);
          case 'update':
            await dio.patch('/tasks/${e.entityId}', data: payload);
          case 'delete':
            await dio.delete('/tasks/${e.entityId}');
          case 'setStatus':
            await dio.post('/tasks/${e.entityId}/status', data: payload);
          case 'reschedule':
            final res =
                await dio.post('/tasks/${e.entityId}/reschedule', data: payload);
            await _applyRescheduleResult(res.data as Map<String, dynamic>);
        }
      case 'category':
        switch (e.op) {
          case 'create':
            await dio.post('/categories', data: payload);
          case 'update':
            await dio.patch('/categories/${e.entityId}', data: payload);
          case 'delete':
            await dio.delete('/categories/${e.entityId}');
        }
      case 'template':
        switch (e.op) {
          case 'create':
            await dio.post('/recurring-templates', data: payload);
          case 'update':
            await dio.patch('/recurring-templates/${e.entityId}', data: payload);
          case 'delete':
            await dio.delete('/recurring-templates/${e.entityId}');
        }
      case 'planning':
        final res = await dio.post('/planning/generate', data: payload);
        final created = (res.data as Map)['created'] as List;
        for (final t in created) {
          await db.upsertTask(taskCompanionFromApi(t as Map<String, dynamic>));
        }
      case 'user':
        await dio.patch('/users/me', data: payload);
    }
  }

  Future<void> _applyRescheduleResult(Map<String, dynamic> data) async {
    for (final key in ['original', 'moved']) {
      final t = data[key];
      if (t is Map<String, dynamic>) {
        await db.upsertTask(taskCompanionFromApi(t));
      }
    }
  }

  // --- Delta pull ------------------------------------------------------------

  /// Pulls server changes since the last watermark into the cache.
  Future<void> pull() async {
    final since = await db.lastServerTime();
    final Response res;
    try {
      res = await dio.get('/sync', queryParameters: {'since': ?since});
    } on DioException catch (e) {
      if (e.response == null) throw _OfflineException();
      rethrow;
    }

    final data = res.data as Map<String, dynamic>;

    await db.transaction(() async {
      for (final c in (data['categories'] as List? ?? const [])) {
        await db.upsertCategory(categoryCompanionFromApi(c as Map<String, dynamic>));
      }
      for (final t in (data['tasks'] as List? ?? const [])) {
        await db.upsertTask(taskCompanionFromApi(t as Map<String, dynamic>));
      }
      for (final tpl in (data['templates'] as List? ?? const [])) {
        await db.upsertTemplate(templateCompanionFromApi(tpl as Map<String, dynamic>));
      }
    });

    // The server includes the user row when its settings changed since `since`.
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      onUserPulled?.call(user);
    }

    final serverTime = data['serverTime'];
    if (serverTime != null) {
      await db.setLastServerTime(serverTime.toString());
    }
  }
}
