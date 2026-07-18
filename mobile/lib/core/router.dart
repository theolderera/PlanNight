import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/recurring_template.dart';
import '../data/models/task.dart';
import '../data/models/user_profile.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_shell.dart';
import '../features/planning/planning_screen.dart';
import '../features/recurring/template_edit_screen.dart';
import '../features/recurring/templates_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tasks/task_edit_screen.dart';
import '../features/today/today_screen.dart';

/// App route paths as constants to avoid stringly-typed navigation mistakes.
class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const today = '/today';
  static const plan = '/plan';
  static const stats = '/stats';
  static const history = '/history';
  static const settings = '/settings';
  static const taskNew = '/task/new';
  static const taskEdit = '/task/edit';
  static const templates = '/templates';
  static const templateNew = '/template/new';
  static const templateEdit = '/template/edit';
  static const categories = '/categories';
}

/// Builds the [GoRouter] and keeps it in sync with auth state.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AsyncValue<UserProfile?>>(const AsyncLoading());
  ref.listen<AsyncValue<UserProfile?>>(
    authControllerProvider,
    (_, next) => refresh.value = next,
    fireImmediately: true,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading || !auth.hasValue) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      final loggedIn = auth.value != null;
      final onAuthPage = loc == Routes.login || loc == Routes.register;

      if (!loggedIn) return onAuthPage ? null : Routes.login;
      if (onAuthPage || loc == Routes.splash) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),

      // Full-screen task editor, pushed over the shell.
      GoRoute(
        path: Routes.taskNew,
        builder: (_, state) =>
            TaskEditScreen(initialDate: state.extra as DateTime?),
      ),
      GoRoute(
        path: Routes.taskEdit,
        builder: (_, state) => TaskEditScreen(task: state.extra as Task),
      ),

      // Recurring templates management.
      GoRoute(
        path: Routes.templates,
        builder: (_, _) => const TemplatesScreen(),
      ),
      GoRoute(
        path: Routes.templateNew,
        builder: (_, _) => const TemplateEditScreen(),
      ),
      GoRoute(
        path: Routes.templateEdit,
        builder: (_, state) =>
            TemplateEditScreen(template: state.extra as RecurringTemplate),
      ),
      GoRoute(
        path: Routes.categories,
        builder: (_, _) => const CategoriesScreen(),
      ),

      // The signed-in shell with five bottom-nav tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.plan, builder: (_, _) => const PlanningScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.stats, builder: (_, _) => const StatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Shown while the app restores a stored session on launch.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
