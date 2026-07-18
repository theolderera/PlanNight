import 'package:flutter/material.dart';

import 'l10n.dart';

/// Client-side calendar helpers. Everything works on the device's local date,
/// which is the user's wall-clock day — matching how the backend stores plans.
///
/// The pure date maths lives here; anything the user *reads* is formatted by
/// [DateLabels] below, which needs an [AppLocalizations].
class Dates {
  const Dates._();

  /// 'YYYY-MM-DD' for a [DateTime] (date part only).
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Today's local date at midnight.
  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime tomorrow() => today().add(const Duration(days: 1));

  static DateTime parse(String iso) => DateTime.parse(iso);

  static DateTime addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day).add(Duration(days: n));

  /// Monday of the week containing [d] (weeks start Monday for the summary).
  static DateTime startOfWeek(DateTime d) {
    final base = DateTime(d.year, d.month, d.day);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Localised date/time formatting.
///
/// We deliberately do NOT use `intl`'s `DateFormat` here. `intl` ships locale
/// data for a fixed list of languages and Tajik is not one of them, so
/// `DateFormat('EEEE, d MMMM y', 'tg')` throws. Names and patterns come from the
/// ARB files instead, which also lets each language pick the right form of a
/// month: Russian needs the genitive inside a date ("8 июля") but the nominative
/// in a header ("Июль 2026"), and Tajik needs the izofat ("8 июли 2026").
class DateLabels {
  const DateLabels(this._l10n);

  final AppLocalizations _l10n;

  /// Convenience: `DateLabels.of(context)`.
  static DateLabels of(BuildContext context) => DateLabels(context.l10n);

  /// Abbreviated weekday for `DateTime.weekday` (1 = Monday .. 7 = Sunday).
  String weekdayShort(int weekday) => switch (weekday) {
        DateTime.monday => _l10n.weekdayShort1,
        DateTime.tuesday => _l10n.weekdayShort2,
        DateTime.wednesday => _l10n.weekdayShort3,
        DateTime.thursday => _l10n.weekdayShort4,
        DateTime.friday => _l10n.weekdayShort5,
        DateTime.saturday => _l10n.weekdayShort6,
        _ => _l10n.weekdayShort7,
      };

  /// Full weekday name for `DateTime.weekday` (1 = Monday .. 7 = Sunday).
  String weekdayLong(int weekday) => switch (weekday) {
        DateTime.monday => _l10n.weekdayLong1,
        DateTime.tuesday => _l10n.weekdayLong2,
        DateTime.wednesday => _l10n.weekdayLong3,
        DateTime.thursday => _l10n.weekdayLong4,
        DateTime.friday => _l10n.weekdayLong5,
        DateTime.saturday => _l10n.weekdayLong6,
        _ => _l10n.weekdayLong7,
      };

  /// Month name on its own, for a calendar header. `month` is 1..12.
  String monthStandalone(int month) => switch (month) {
        1 => _l10n.monthStandalone1,
        2 => _l10n.monthStandalone2,
        3 => _l10n.monthStandalone3,
        4 => _l10n.monthStandalone4,
        5 => _l10n.monthStandalone5,
        6 => _l10n.monthStandalone6,
        7 => _l10n.monthStandalone7,
        8 => _l10n.monthStandalone8,
        9 => _l10n.monthStandalone9,
        10 => _l10n.monthStandalone10,
        11 => _l10n.monthStandalone11,
        _ => _l10n.monthStandalone12,
      };

  /// Month name as it appears inside a full date. `month` is 1..12.
  String monthInDate(int month) => switch (month) {
        1 => _l10n.monthInDate1,
        2 => _l10n.monthInDate2,
        3 => _l10n.monthInDate3,
        4 => _l10n.monthInDate4,
        5 => _l10n.monthInDate5,
        6 => _l10n.monthInDate6,
        7 => _l10n.monthInDate7,
        8 => _l10n.monthInDate8,
        9 => _l10n.monthInDate9,
        10 => _l10n.monthInDate10,
        11 => _l10n.monthInDate11,
        _ => _l10n.monthInDate12,
      };

  /// The seven abbreviated weekday names in display order, Monday first.
  List<String> get weekdayHeadings =>
      [for (var w = DateTime.monday; w <= DateTime.sunday; w++) weekdayShort(w)];

  /// e.g. "Wed, 8 Jul" — used in the stats week range.
  String short(DateTime d) => _l10n.dateShort(
        weekdayShort(d.weekday),
        d.day,
        monthInDate(d.month),
      );

  /// e.g. "Wednesday, 8 July 2026".
  String long(DateTime d) => _l10n.dateLong(
        weekdayLong(d.weekday),
        d.day,
        monthInDate(d.month),
        d.year,
      );

  /// e.g. "July 2026" — the calendar header.
  String monthAndYear(DateTime d) =>
      _l10n.monthAndYear(monthStandalone(d.month), d.year);

  /// A relative label for day headers: Today / Tomorrow / Yesterday / date.
  String relative(DateTime d) {
    final t = Dates.today();
    if (Dates.isSameDay(d, t)) return _l10n.today;
    if (Dates.isSameDay(d, t.add(const Duration(days: 1)))) return _l10n.tomorrow;
    if (Dates.isSameDay(d, t.subtract(const Duration(days: 1)))) {
      return _l10n.yesterday;
    }
    return short(d);
  }

  /// Format an 'HH:MM' string honouring the device's 12/24h setting. Returns the
  /// localised "Anytime" for a task with no start time.
  ///
  /// [TimeOfDay.format] reads `MaterialLocalizations`, which under a Tajik
  /// locale is served by the fallback delegate in `core/l10n.dart`.
  String time(BuildContext context, String? hhmm) {
    if (hhmm == null) return _l10n.anytime;
    final parts = hhmm.split(':');
    if (parts.length < 2) return _l10n.anytime;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return _l10n.anytime;
    return TimeOfDay(hour: h, minute: m).format(context);
  }
}
