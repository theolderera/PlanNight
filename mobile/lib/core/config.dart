/// Compile-time app configuration.
///
/// The API base URL is provided via `--dart-define=API_BASE_URL=...` so the same
/// code can point at localhost, an emulator host, or your Hetzner server without
/// editing source. Sensible default targets the Android emulator, which reaches
/// the host machine's localhost via the special IP 10.0.2.2.
///
/// Examples:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
///   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api
library;

class AppConfig {
  const AppConfig._();

  /// Base URL for the REST API, including the `/api` prefix.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
}
