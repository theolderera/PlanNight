import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../data/ui_providers.dart';
import '../auth/auth_controller.dart';
import 'notification_service.dart';

/// The notification service singleton (initialised in main()).
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Keeps scheduled reminders in sync with the next week of tasks and the user's
/// notification settings. Watched at the app root; re-runs (cancel + reschedule)
/// whenever the upcoming tasks or preferences change.
final notificationSchedulerProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return;

  final range = (
    from: Dates.iso(Dates.today()),
    to: Dates.iso(Dates.addDays(Dates.today(), 7)),
  );
  final tasks = ref.watch(tasksInRangeProvider(range)).value ?? const [];

  // Fire-and-forget; scheduleForTasks is idempotent (cancels then reschedules).
  // Re-runs when `user.language` changes, so already-scheduled reminders are
  // rewritten in the new language rather than firing in the old one.
  service.scheduleForTasks(
    tasks,
    enabled: user.notificationsEnabled,
    defaultLead: user.reminderLeadMinutes,
    languageCode: user.language,
    eveningReminderEnabled: user.eveningReminderEnabled,
    eveningReminderTime: user.eveningReminderTime,
  );
});
