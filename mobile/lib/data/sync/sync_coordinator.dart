import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../features/auth/auth_controller.dart';
import '../local/database.dart';
import '../models/user_profile.dart';
import 'sync_engine.dart';

/// Wires together the triggers that drive syncing:
///   * on login (or app-start session restore) → full sync
///   * on logout → wipe the local cache
///   * on regaining connectivity → sync
class SyncCoordinator {
  SyncCoordinator(this._sync, this._db) {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _sync.syncNow();
    });
  }

  final SyncEngine _sync;
  final AppDatabase _db;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void onLogin() => _sync.syncNow();

  Future<void> onLogout() => _db.clearAll();

  void dispose() {
    _connectivitySub?.cancel();
  }
}

/// Instantiating this provider (watched at the app root) activates the sync
/// triggers and reacts to auth-state changes.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final engine = ref.watch(syncEngineProvider);
  final coordinator = SyncCoordinator(engine, ref.watch(databaseProvider));

  // A pull can bring back settings changed on another device (theme, language,
  // streak threshold). Publish them so the UI actually reflects them.
  engine.onUserPulled = (json) {
    ref.read(authControllerProvider.notifier).updateUser(UserProfile.fromJson(json));
  };

  // React to future auth transitions.
  ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
    final was = prev?.value != null;
    final now = next.value != null;
    if (!was && now) coordinator.onLogin();
    if (was && !now) coordinator.onLogout();
  });

  // Cover the case where we're already signed in when this is first created.
  if (ref.read(authControllerProvider).value != null) {
    coordinator.onLogin();
  }

  ref.onDispose(coordinator.dispose);
  return coordinator;
});
