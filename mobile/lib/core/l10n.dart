import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart' show AppLocalizations;

/// `context.l10n.addTask` reads better at call sites than
/// `AppLocalizations.of(context).addTask`, and it's what the screens use.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Translations for code that has no `BuildContext` — notably the notification
/// service, which builds its text on a background isolate long after the widget
/// that scheduled it is gone.
AppLocalizations l10nFor(String? languageCode) =>
    lookupAppLocalizations(AppLocale.fromCode(languageCode).locale);

/// The languages PlanNight ships translations for.
///
/// The `code` is what the backend stores in `users.language` (see migration
/// 002) and what `Locale(code)` is built from. `nativeName` is deliberately
/// written in the language itself — a user who has accidentally switched to a
/// language they can't read still needs to find their way back.
enum AppLocale {
  english('en', 'English'),
  russian('ru', 'Русский'),
  tajik('tg', 'Тоҷикӣ');

  const AppLocale(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  /// Resolve a stored/`Platform` language code, falling back to English for
  /// anything we don't translate.
  static AppLocale fromCode(String? code) => values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLocale.english,
      );

  /// True when we ship a translation for this language code.
  static bool isSupported(String? code) => values.any((l) => l.code == code);
}

/// Every locale the app can be displayed in.
final supportedLocales = [for (final l in AppLocale.values) l.locale];

// -----------------------------------------------------------------------------
// Tajik support for Flutter's *built-in* widget strings.
//
// AppLocalizations (our ARB files) covers everything PlanNight itself renders.
// But Material and Cupertino ship their own translations for the strings inside
// framework widgets — the date picker's "Cancel"/"OK", the time picker's
// "Select minutes", a TextField's "Paste" menu — and `GlobalMaterialLocalizations`
// simply has no `tg`. Without a delegate that claims to support it, pushing
// `showDatePicker` under a Tajik locale throws at runtime.
//
// Tajik is written in Cyrillic and most speakers here read Russian, so we serve
// the Russian framework strings for those widgets. Only the framework's own
// labels are affected; every PlanNight string still comes from app_tg.arb.
// -----------------------------------------------------------------------------

/// The locale whose framework translations stand in for Tajik.
const _tajikFrameworkFallback = Locale('ru');

class _TajikMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TajikMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == AppLocale.tajik.code;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_tajikFrameworkFallback);

  @override
  bool shouldReload(_TajikMaterialLocalizationsDelegate old) => false;
}

class _TajikCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TajikCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == AppLocale.tajik.code;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_tajikFrameworkFallback);

  @override
  bool shouldReload(_TajikCupertinoLocalizationsDelegate old) => false;
}

/// Delegates for `MaterialApp.localizationsDelegates`.
///
/// Order matters: Flutter picks the FIRST delegate that claims a locale, so the
/// Tajik stand-ins must precede the Global* delegates. (Global*WidgetsLocalizations
/// supports every locale already — it only supplies text direction.)
const localizationsDelegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  _TajikMaterialLocalizationsDelegate(),
  _TajikCupertinoLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
