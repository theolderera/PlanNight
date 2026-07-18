import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

/// Global authentication/session state.
///
/// The value is the signed-in [UserProfile], or `null` when signed out. During
/// app start `build()` tries to restore a session from stored tokens, so the
/// state is briefly `AsyncLoading` (the router shows a splash meanwhile).
///
/// Login/register themselves are performed by the screens via [AuthRepository]
/// (so they can own their own form/loading/error state); on success they call
/// [setSession] to publish the user here.
class AuthController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final access = await ref.read(tokenStorageProvider).readAccess();
    if (access == null) return null;
    try {
      // Restore the session. If the token is stale, the API client's refresh
      // interceptor handles it; if that also fails it triggers forceLogout.
      return await ref.read(authRepositoryProvider).getMe();
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      return null;
    }
  }

  /// Publish a freshly-authenticated user (called after login/register).
  void setSession(UserProfile user) => state = AsyncData(user);

  /// Reflect a server copy of the profile (e.g. settings changed on another
  /// device and pulled by the sync engine).
  ///
  /// Ignored when signed out: a pull racing a logout must never resurrect the
  /// session and bounce the router back into the app.
  void updateUser(UserProfile user) {
    if (state.value == null) return;
    state = AsyncData(user);
  }

  /// Update the user's settings: apply optimistically, queue the change in the
  /// outbox (so it syncs like any other write), and kick a sync.
  Future<void> updateSettings({
    String? theme,
    String? language,
    int? streakThresholdPct,
    bool? notificationsEnabled,
    int? reminderLeadMinutes,
    bool? eveningReminderEnabled,
    String? eveningReminderTime,
    String? timezone,
  }) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      theme: theme,
      language: language,
      streakThresholdPct: streakThresholdPct,
      notificationsEnabled: notificationsEnabled,
      reminderLeadMinutes: reminderLeadMinutes,
      eveningReminderEnabled: eveningReminderEnabled,
      eveningReminderTime: eveningReminderTime,
      timezone: timezone,
    ));

    // Null-aware elements: each entry is omitted when its value is null.
    final patch = <String, dynamic>{
      'theme': ?theme,
      'language': ?language,
      'streakThresholdPct': ?streakThresholdPct,
      'notificationsEnabled': ?notificationsEnabled,
      'reminderLeadMinutes': ?reminderLeadMinutes,
      'eveningReminderEnabled': ?eveningReminderEnabled,
      'eveningReminderTime': ?eveningReminderTime,
      'timezone': ?timezone,
    };
    await ref.read(databaseProvider).enqueue(OutboxEntriesCompanion.insert(
          entityType: 'user',
          entityId: current.id,
          op: 'update',
          payloadJson: Value(jsonEncode(patch)),
          createdAt: DateTime.now(),
        ));
    ref.read(syncEngineProvider).syncNow();
  }

  /// User-initiated sign out.
  ///
  /// Order matters to avoid losing local work: first flush any queued writes to
  /// the server *while still authenticated*, then revoke the session, then wipe
  /// the local cache (so the next person on this device can't read it). If the
  /// flush fails (offline) with writes still pending, the cache is KEPT rather
  /// than destroyed — the user can reconnect and sync, or sign back in.
  Future<void> logout() async {
    // Best-effort push of pending local edits before we tear anything down.
    try {
      await ref.read(syncEngineProvider).flushOutbox();
    } catch (_) {/* offline — fall through */}

    final pending = await ref.read(databaseProvider).pendingOutbox();

    await ref.read(authRepositoryProvider).logout(); // revoke + clear tokens
    if (pending.isEmpty) {
      // Everything is safely on the server — clear the local copy.
      await ref.read(databaseProvider).clearAll();
    }
    // else: unsynced writes remain; keep the cache so they aren't lost.
    state = const AsyncData(null);
  }

  /// Called by the API client when the session can't be refreshed (token
  /// expired/rotated, etc). This is INVOLUNTARY, so it must never destroy data:
  /// we only drop the tokens and return to the login screen. The local cache —
  /// including any not-yet-synced outbox writes — is left intact and re-syncs
  /// on the next successful login. (An earlier version wiped the cache here,
  /// which lost unsynced work whenever a session expired.)
  Future<void> forceLogout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);
