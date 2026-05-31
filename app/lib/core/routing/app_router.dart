import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alarm/presentation/alarm_screen.dart';
import '../../features/eyecare/presentation/eyecare_settings_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stopwatch/presentation/stopwatch_screen.dart';
import '../../features/timer/presentation/timer_screen.dart';
import '../../features/todos/presentation/todos_screen.dart';
import '../widgets/app_scaffold.dart';

/// App route paths.
abstract final class Routes {
  static const focus = '/focus';
  static const timer = '/timer';
  static const alarm = '/alarm';
  static const stopwatch = '/stopwatch';
  static const insights = '/insights';
  static const settings = '/settings';
  static const eyeCareSettings = '/settings/eyecare';
  static const tasks = '/tasks';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.focus,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.focus,
                builder: (context, state) => const FocusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.timer,
                builder: (context, state) => const TimerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.alarm,
                builder: (context, state) => const AlarmScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stopwatch,
                builder: (context, state) => const StopwatchScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.insights,
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.eyeCareSettings,
        builder: (context, state) => const EyeCareSettingsScreen(),
      ),
      GoRoute(
        path: Routes.tasks,
        builder: (context, state) => const TodosScreen(),
      ),
    ],
  );
});
