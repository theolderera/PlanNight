import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart' as l10n;
import 'core/router.dart';
import 'core/theme.dart';
import 'data/sync/sync_coordinator.dart';
import 'features/auth/auth_controller.dart';
import 'features/notifications/notification_providers.dart';
import 'features/notifications/notification_service.dart';

/// Root widget. Wires the router, applies the user's theme preference, and
/// activates the sync + notification-scheduling background providers.
class PlanNightApp extends ConsumerStatefulWidget {
  const PlanNightApp({super.key});

  @override
  ConsumerState<PlanNightApp> createState() => _PlanNightAppState();
}

class _PlanNightAppState extends ConsumerState<PlanNightApp> {
  @override
  void initState() {
    super.initState();
    // When the user becomes authenticated, ask for notification permission once.
    ref.listenManual(authControllerProvider, (prev, next) {
      final becameLoggedIn = prev?.value == null && next.value != null;
      if (becameLoggedIn) {
        ref.read(notificationServiceProvider).requestPermissions();
      }
    });

    // Route when a notification is tapped: the evening "plan tomorrow" nudge
    // opens the Plan screen; task reminders open Today. Registered once:
    // build() runs on every rebuild, and re-assigning a static callback there
    // was pointless work (and a trap for anyone adding state to the closure).
    NotificationService.onSelectPayload = (payload) {
      final router = ref.read(routerProvider);
      router.go(payload == NotificationService.planTomorrowPayload
          ? Routes.plan
          : Routes.today);
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Keep the background coordinators alive for the app's lifetime.
    ref.watch(syncCoordinatorProvider);
    ref.watch(notificationSchedulerProvider);

    final themePref =
        ref.watch(authControllerProvider.select((s) => s.value?.theme));

    // The signed-in user's language. Null before sign-in (and while the session
    // is being restored), which lets `MaterialApp` resolve the device locale
    // against `supportedLocales` — so the login screen already greets the user
    // in Russian or Tajik if that's what their phone is set to.
    final languagePref =
        ref.watch(authControllerProvider.select((s) => s.value?.language));

    return MaterialApp.router(
      title: 'PlanNight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.modeFromString(themePref),
      locale: languagePref == null ? null : l10n.AppLocale.fromCode(languagePref).locale,
      supportedLocales: l10n.supportedLocales,
      localizationsDelegates: l10n.localizationsDelegates,
      routerConfig: router,
    );
  }
}
