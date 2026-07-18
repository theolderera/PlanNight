// Localisation checks for the three shipped languages.
//
// The Tajik cases matter most: Flutter has no built-in `tg` translations and
// `intl` has no `tg` date symbols, so both are handled by hand — a Material
// fallback delegate, and month/weekday names read from the ARB files. Without
// those, opening a date picker under a Tajik locale throws at runtime.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/core/date_utils.dart';
import 'package:plannight/core/l10n.dart';
import 'package:plannight/core/reminder_options.dart';
import 'package:plannight/data/models/task.dart';

/// Pumps a minimal app in [locale] and hands the resulting context back.
Future<BuildContext> pumpLocalized(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegates,
    home: Builder(builder: (context) {
      captured = context;
      return const Scaffold(body: SizedBox.shrink());
    }),
  ));
  return captured;
}

void main() {
  group('AppLocale', () {
    test('maps known codes and falls back to English', () {
      expect(AppLocale.fromCode('ru'), AppLocale.russian);
      expect(AppLocale.fromCode('tg'), AppLocale.tajik);
      expect(AppLocale.fromCode('uz'), AppLocale.english, reason: 'untranslated');
      expect(AppLocale.fromCode(null), AppLocale.english);
    });

    test('isSupported gates the device-language sniff at sign-up', () {
      expect(AppLocale.isSupported('tg'), isTrue);
      expect(AppLocale.isSupported('de'), isFalse);
    });

    test('every language names itself in its own script', () {
      expect(AppLocale.russian.nativeName, 'Русский');
      expect(AppLocale.tajik.nativeName, 'Тоҷикӣ');
    });
  });

  group('l10nFor (no BuildContext — used by the notification service)', () {
    test('resolves each shipped language', () {
      expect(l10nFor('en').navToday, 'Today');
      expect(l10nFor('ru').navToday, 'Сегодня');
      expect(l10nFor('tg').navToday, 'Имрӯз');
    });

    test('an unshipped language falls back to English rather than throwing', () {
      expect(l10nFor('de').navToday, 'Today');
    });
  });

  group('every screen string is actually translated', () {
    // A missing key would silently fall through to English. Spot-check one
    // string per screen area in both non-English locales.
    for (final code in ['ru', 'tg']) {
      test('$code has no English leakage in sampled keys', () {
        final l = l10nFor(code);
        final en = l10nFor('en');
        final sampled = <String, String Function(AppLocalizations)>{
          'addTask': (x) => x.addTask,
          'navSettings': (x) => x.navSettings,
          'priorityHigh': (x) => x.priorityHigh,
          'logOut': (x) => x.logOut,
          'everyDay': (x) => x.everyDay,
          'noCategoriesMessage': (x) => x.noCategoriesMessage,
          'errorBadCredentials': (x) => x.errorBadCredentials,
          'notificationChannelName': (x) => x.notificationChannelName,
          'completionByDay': (x) => x.completionByDay,
          'anytime': (x) => x.anytime,
        };
        for (final entry in sampled.entries) {
          expect(entry.value(l), isNot(entry.value(en)),
              reason: '"${entry.key}" is still English in $code');
        }
      });
    }
  });

  group('DateLabels', () {
    final wednesday = DateTime(2026, 7, 8); // a Wednesday

    test('English long date', () {
      expect(DateLabels(l10nFor('en')).long(wednesday), 'Wednesday, 8 July 2026');
    });

    test('Russian uses the genitive month inside a date, nominative in a header', () {
      final ru = DateLabels(l10nFor('ru'));
      expect(ru.long(wednesday), 'Среда, 8 июля 2026');
      expect(ru.monthAndYear(wednesday), 'Июль 2026');
    });

    test('Tajik uses the izofat month inside a date', () {
      final tg = DateLabels(l10nFor('tg'));
      expect(tg.long(wednesday), 'Чоршанбе, 8 июли 2026');
      expect(tg.monthAndYear(wednesday), 'Июл 2026');
    });

    test('weekday headings run Monday..Sunday', () {
      expect(DateLabels(l10nFor('tg')).weekdayHeadings,
          ['Дш', 'Сш', 'Чш', 'Пш', 'Ҷм', 'Шн', 'Яш']);
      expect(DateLabels(l10nFor('ru')).weekdayHeadings.first, 'Пн');
    });

    test('relative labels for today / tomorrow / yesterday', () {
      final tg = DateLabels(l10nFor('tg'));
      expect(tg.relative(Dates.today()), 'Имрӯз');
      expect(tg.relative(Dates.tomorrow()), 'Фардо');
      expect(tg.relative(Dates.addDays(Dates.today(), -1)), 'Дирӯз');
    });

    testWidgets('a null start time renders the localised "Anytime"', (tester) async {
      final context = await pumpLocalized(tester, const Locale('tg'));
      expect(DateLabels(l10nFor('tg')).time(context, null), 'Ҳар вақт');
    });

    testWidgets('a malformed time string degrades to "Anytime" instead of throwing',
        (tester) async {
      final context = await pumpLocalized(tester, const Locale('en'));
      expect(DateLabels(l10nFor('en')).time(context, 'not-a-time'), 'Anytime');
    });
  });

  group('Priority labels follow the locale', () {
    test('each language, each value', () {
      expect(Priority.high.label(l10nFor('en')), 'High');
      expect(Priority.medium.label(l10nFor('ru')), 'Средний');
      expect(Priority.low.label(l10nFor('tg')), 'Паст');
    });
  });

  group('reminder lead labels', () {
    test('0 and 60 get their own wording, the rest are generic', () {
      final en = l10nFor('en');
      expect(reminderLeadLabel(en, 0), 'At start time');
      expect(reminderLeadLabel(en, 60), '1 hour before');
      expect(reminderLeadLabel(en, 15), '15 minutes before');
    });

    test('every offered option has a label in every language', () {
      for (final code in ['en', 'ru', 'tg']) {
        for (final minutes in reminderLeadMinutesOptions) {
          expect(reminderLeadLabel(l10nFor(code), minutes), isNotEmpty);
        }
      }
    });
  });

  group('Flutter framework widgets under each locale', () {
    // GlobalMaterialLocalizations has no `tg`. If our fallback delegate were
    // missing, `MaterialLocalizations.of(context)` would throw here.
    for (final code in ['en', 'ru', 'tg']) {
      testWidgets('$code resolves MaterialLocalizations', (tester) async {
        final context = await pumpLocalized(tester, Locale(code));
        expect(MaterialLocalizations.of(context), isNotNull);
      });
    }

    testWidgets('Tajik borrows the Russian framework strings', (tester) async {
      final context = await pumpLocalized(tester, const Locale('tg'));
      // "Cancel" comes from Material, not from our ARB files.
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Отмена');
    });

    testWidgets('showDatePicker opens under a Tajik locale', (tester) async {
      final context = await pumpLocalized(tester, const Locale('tg'));
      showDatePicker(
        context: context,
        initialDate: DateTime(2026, 7, 8),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}
