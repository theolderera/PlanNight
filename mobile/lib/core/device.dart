import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_timezone/flutter_timezone.dart';

import 'l10n.dart';

/// Best-effort IANA timezone identifier for this device (e.g. 'Asia/Karachi').
/// Falls back to 'UTC' if the platform can't provide one. The backend uses this
/// to roll a user's "day" over at their local midnight for streaks.
Future<String> getDeviceTimezone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  } catch (_) {
    return 'UTC';
  }
}

/// The device's UI language, if PlanNight is translated into it.
///
/// Returns null when the phone is set to a language we don't ship (say, Uzbek),
/// so the caller can leave the field out and let the backend apply its own
/// default rather than forcing the account into the wrong language.
String? getDeviceLanguage() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return AppLocale.isSupported(code) ? code : null;
}
