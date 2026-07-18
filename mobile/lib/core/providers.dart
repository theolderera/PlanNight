import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../data/local/database.dart';
import '../data/local/token_storage.dart';
import '../data/sync/sync_engine.dart';
import '../features/auth/auth_controller.dart';

/// Secure JWT storage (singleton for the app's lifetime).
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// The configured Dio API client. On an unrecoverable 401 it asks the auth
/// controller to end the session (which flips the router back to /login).
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: () async {
      await ref.read(authControllerProvider.notifier).forceLogout();
    },
  );
  ref.onDispose(() => client.dio.close());
  return client;
});

/// The local drift database (single instance for the app's lifetime).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Offline-first sync engine bridging the cache and the API.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    dio: ref.watch(apiClientProvider).dio,
    db: ref.watch(databaseProvider),
  );
});
