import 'l10n.dart';

/// The reminder lead times the user can pick, in minutes before a task starts.
///
/// The same list backs the task editor, the template editor and the default in
/// Settings, so a value shown in one place always exists in the others. `0`
/// means "at the start time".
const reminderLeadMinutesOptions = <int>[0, 5, 10, 15, 30, 60];

/// The translated label for a lead time, e.g. "15 minutes before".
///
/// An unknown value (say, a lead time set on another client) falls back to the
/// generic "N minutes before" rather than showing a raw number.
String reminderLeadLabel(AppLocalizations l10n, int minutes) => switch (minutes) {
      0 => l10n.reminderAtStart,
      60 => l10n.reminderOneHourBefore,
      _ => l10n.reminderMinutesBefore(minutes),
    };
