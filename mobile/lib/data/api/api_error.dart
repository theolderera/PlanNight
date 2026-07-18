import 'package:dio/dio.dart';

import '../../core/l10n.dart';

/// Turns any error thrown by the API layer into a message we can show a user,
/// in *their* language.
///
/// The backend answers with `{ error: { message, code? } }`. Its `message` is
/// English prose written for developers and logs; showing it raw would leak
/// English into a Russian or Tajik UI. So we key off the stable machine-readable
/// `code` and look the text up in the ARB files, falling back — in order — to:
///
///   1. a localised message for the transport failure (offline, timeout),
///   2. the caller's context-specific fallback ("Login failed"),
///   3. a generic "Something went wrong".
///
/// The server's own `message` is deliberately never rendered: an unrecognised
/// code means we forgot to translate something, and a generic sentence is a
/// better user experience than a stray English one.
String apiErrorMessage(
  AppLocalizations l10n,
  Object error, {
  String? fallback,
}) {
  if (error is DioException) {
    // Transport-level failures never reach the server, so they have no code.
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return l10n.serverTookTooLong;
      case DioExceptionType.connectionError:
        return l10n.cannotReachServer;
      default:
        break;
    }

    // The auth endpoints are rate limited and answer 429 without a code.
    if (error.response?.statusCode == 429) return l10n.errorTooManyAttempts;

    final localised = _messageForCode(l10n, _codeOf(error.response?.data));
    if (localised != null) return localised;
  }

  return fallback ?? l10n.somethingWentWrong;
}

/// Pull `error.code` out of a response body, tolerating any shape.
String? _codeOf(Object? data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is! Map) return null;
  final code = error['code'];
  return code is String ? code : null;
}

/// Maps the backend's stable error codes to translated text.
/// Keep in sync with the `ApiError` codes thrown in `backend/src`.
String? _messageForCode(AppLocalizations l10n, String? code) => switch (code) {
      'EMAIL_TAKEN' => l10n.errorEmailTaken,
      'BAD_CREDENTIALS' => l10n.errorBadCredentials,
      'REFRESH_INVALID' || 'USER_GONE' || 'TOKEN_INVALID' => l10n.errorSessionExpired,
      'CATEGORY_NOT_FOUND' => l10n.errorCategoryNotFound,
      'CATEGORY_EXISTS' || 'DUPLICATE' => l10n.errorCategoryExists,
      'VALIDATION_ERROR' || 'EMPTY_PATCH' => l10n.errorValidation,
      'SAME_DATE' => l10n.errorSameDate,
      _ => null,
    };
