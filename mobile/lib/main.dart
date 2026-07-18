import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/notifications/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A container we can use before the widget tree exists, then hand to the app
  // via UncontrolledProviderScope so the same instances are reused.
  final container = ProviderContainer();
  // Initialise local notifications (timezone db + plugin) up front.
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PlanNightApp(),
    ),
  );
}
