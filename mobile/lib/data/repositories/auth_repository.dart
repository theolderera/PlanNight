import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../api/api_client.dart';
import '../local/token_storage.dart';
import '../models/user_profile.dart';

/// Handles authentication network calls and token persistence.
class AuthRepository {
  AuthRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStorage _tokens;

  /// Register a new account; on success persists tokens and returns the profile.
  Future<UserProfile> register({
    required String email,
    required String password,
    String? timezone,
    String? language,
  }) async {
    final res = await _client.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      // Null-aware elements: each entry is omitted when its value is null, so
      // the backend applies its own default instead of receiving an explicit
      // null (which its validation would reject).
      'timezone': ?timezone,
      'language': ?language,
    });
    return _handleAuthResponse(res.data as Map<String, dynamic>);
  }

  /// Log in; on success persists tokens and returns the profile.
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(res.data as Map<String, dynamic>);
  }

  /// Fetch the current user (used to restore a session on app start).
  Future<UserProfile> getMe() async {
    final res = await _client.dio.get('/users/me');
    return UserProfile.fromJson((res.data as Map)['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _tokens.clear();

  Future<UserProfile> _handleAuthResponse(Map<String, dynamic> data) async {
    await _tokens.save(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
