import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/date_utils.dart';
import '../../core/device.dart';
import '../../core/l10n.dart';
// Hide our own Priority enum here; this file uses the plugin's Priority.
import '../../data/models/task.dart' hide Priority;

/// Schedules on-device local notifications at each task's start time (minus an
/// optional lead), based on the times synced from the backend. No push service
/// is used. Tapping a notification deep-links via [onSelectPayload].
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inited = false;

  /// Set by the app to handle a tapped notification. Receives the payload:
  /// [planTomorrowPayload] for the evening nudge, 'YYYY-MM-DD|taskId' for a
  /// task reminder.
  static void Function(String? payload)? onSelectPayload;

  /// Payload of the evening "plan tomorrow" nudge — the app routes it to /plan.
  static const planTomorrowPayload = 'plan-tomorrow';

  /// Fixed id for the single daily evening nudge. Task ids are masked to 31
  /// bits (always >= 0 stays possible), so a negative id can never collide.
  static const _eveningReminderId = -1;

  static const _channelId = 'task_reminders';

  /// Initialise the plugin and the timezone database. Safe to call more than
  /// once. On non-mobile platforms this is a no-op.
  Future<void> init() async {
    if (_inited || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await getDeviceTimezone()));
    } catch (_) {
      // Fall back to whatever tz.local defaults to.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (resp) =>
          onSelectPayload?.call(resp.payload),
    );
    _inited = true;
  }

  /// Ask for notification (and exact-alarm) permission. Call after login.
  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// The channel's user-visible name and description appear in Android's system
  /// notification settings, so they are translated too.
  ///
  /// Note that Android caches a channel by its id the first time it's created:
  /// changing the language updates the strings we pass here, but the system
  /// keeps showing the original ones until the app is reinstalled. Users see
  /// this screen rarely; recreating the channel on every language change would
  /// reset the user's own per-channel sound/importance overrides, which is worse.
  NotificationDetails _details(AppLocalizations l10n) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.notificationChannelName,
          channelDescription: l10n.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// Cancel everything and re-schedule all local notifications: per-task
  /// reminders for the given (upcoming) tasks, plus the daily evening
  /// "plan tomorrow" nudge. Idempotent — call whenever tasks/settings change.
  ///
  /// [languageCode] is the signed-in user's language: notifications are composed
  /// now but fire hours later, with no widget tree to read a locale from.
  Future<void> scheduleForTasks(
    List<Task> tasks, {
    required bool enabled,
    required int defaultLead,
    required String languageCode,
    required bool eveningReminderEnabled,
    required String eveningReminderTime,
  }) async {
    if (!_inited || kIsWeb) return;
    await _plugin.cancelAll();

    final l10n = l10nFor(languageCode);
    final details = _details(l10n);

    // The evening nudge rides the master notifications switch too: "Task
    // reminders: off" should mean a fully silent app.
    if (enabled && eveningReminderEnabled) {
      await _scheduleEveningReminder(l10n, details, eveningReminderTime);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);

    for (final t in tasks) {
      // Only pending, timed tasks get a reminder.
      if (t.startTime == null || t.status != TaskStatus.planned) continue;
      final lead = t.reminderLeadMinutes ?? defaultLead;
      final when = _whenFor(t, lead);
      if (when == null || !when.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: t.id.hashCode & 0x7fffffff,
        title: t.title,
        body: l10n.notificationScheduledFor(t.startTime!),
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '${Dates.iso(t.planDate)}|${t.id}',
      );
    }
  }

  /// Schedule the daily "plan tomorrow" nudge at the user's chosen wall-clock
  /// time. `matchDateTimeComponents: time` makes it repeat every day at that
  /// time; if today's slot already passed, the first fire is tomorrow.
  Future<void> _scheduleEveningReminder(
    AppLocalizations l10n,
    NotificationDetails details,
    String hhmm,
  ) async {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 21;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _eveningReminderId,
      title: l10n.eveningReminderTitle,
      body: l10n.eveningReminderBody,
      scheduledDate: first,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: planTomorrowPayload,
    );
  }

  /// The local wall-clock instant a task's reminder should fire.
  tz.TZDateTime? _whenFor(Task t, int lead) {
    final time = t.startTime;
    if (time == null) return null;
    final parts = time.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (h == null || m == null) return null;
    final d = t.planDate;
    return tz.TZDateTime(tz.local, d.year, d.month, d.day, h, m)
        .subtract(Duration(minutes: lead));
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
