import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../local/token_storage.dart';

/// Thin wrapper around Dio that:
///   * points at [AppConfig.apiBaseUrl],
///   * attaches the Bearer access token to every request,
///   * transparently refreshes the access token once on a 401 and retries,
///   * calls [onSessionExpired] when the refresh also fails (forces re-login).
///
/// Expose the underlying [dio] to the feature-specific API classes.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, required this.onSessionExpired})
      : _tokens = tokenStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        // Default validateStatus (only 2xx succeeds) is exactly what we want:
        // any 4xx/5xx throws a DioException, so the 401 refresh interceptor fires
        // and repositories can catch failures uniformly via apiErrorMessage().
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  late final Dio dio;
  final TokenStorage _tokens;

  /// Called when the session can no longer be refreshed (log the user out).
  final Future<void> Function() onSessionExpired;

  // Guards against many concurrent 401s all trying to refresh at once.
  Future<String?>? _refreshFuture;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't attach tokens to the auth endpoints themselves.
    if (!options.path.startsWith('/auth/')) {
      final access = await _tokens.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final isAuthCall = error.requestOptions.path.startsWith('/auth/');

    // Only try to recover from a 401 on a normal (already-retried?) request.
    final alreadyRetried = error.requestOptions.extra['retried'] == true;
    if (response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
      final newAccess = await _refreshAccessToken();
      if (newAccess != null) {
        // Retry the original request once with the fresh token.
        final opts = error.requestOptions
          ..extra['retried'] = true
          ..headers['Authorization'] = 'Bearer $newAccess';
        try {
          final retried = await dio.fetch(opts);
          return handler.resolve(retried);
        } catch (e) {
          return handler.next(e is DioException ? e : error);
        }
      }
    }
    handler.next(error);
  }

  /// Refreshes the access token, coalescing concurrent callers onto one request.
  /// Returns the new access token, or null if refresh failed (session expired).
  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) {
      await onSessionExpired();
      return null;
    }

    // A bare Dio, so this call doesn't recurse back through our interceptor.
    // Closed in `finally` — a fresh client per refresh otherwise leaks its
    // HttpClient (and its idle connections) for the life of the app.
    final bare = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    try {
      final res = await bare.post('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data;
      // Be defensive about the shape: a proxy or captive portal can return 200
      // with an HTML body, and a blind `as String` would throw a TypeError that
      // never surfaces as "your session expired".
      if (res.statusCode == 200 && data is Map && data['accessToken'] is String) {
        final access = data['accessToken'] as String;
        final newRefresh = data['refreshToken'];
        if (newRefresh is String) {
          await _tokens.save(access: access, refresh: newRefresh);
        } else {
          await _tokens.updateAccess(access);
        }
        return access;
      }
    } on DioException {
      // fall through to session-expired
    } finally {
      bare.close();
    }

    await onSessionExpired();
    return null;
  }
}
