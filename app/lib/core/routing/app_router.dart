import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/alarm/domain/alarm_item.dart';
import '../../features/alarm/presentation/alarm_editor_screen.dart';
import '../../features/alarm/presentation/alarm_ringing_screen.dart';
import '../../features/alarm/presentation/alarm_screen.dart';
import '../../features/eyecare/presentation/break_screen.dart';
import '../../features/eyecare/presentation/eyecare_settings_screen.dart';
import '../../features/eyecare/presentation/location_picker_screen.dart';
import '../../features/focus/presentation/active_session_shelf.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stopwatch/presentation/stopwatch_screen.dart';
import '../../features/timer/presentation/timer_screen.dart';
import '../../features/todos/presentation/todos_screen.dart';
import '../settings/settings_controller.dart';
import '../widgets/app_scaffold.dart';

/// App route paths.
abstract final class Routes {
  static const focus = '/focus';
  static const focusSession = '/focus-session';
  static const timer = '/timer';
  static const alarm = '/alarm';
  static const alarmRinging = '/alarm-ringing';
  static const alarmEditor = '/alarm-edit';
  static const stopwatch = '/stopwatch';
  static const insights = '/insights';
  static const settings = '/settings';
  static const eyeCareSettings = '/settings/eyecare';
  static const locationPicker = '/settings/prayer-location';
  static const eyeCareBreak = '/eyecare/break';
  static const account = '/settings/account';
  static const tasks = '/tasks';
  static const onboarding = '/onboarding';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.focus,
    redirect: (context, state) {
      // Debug/screenshot flag (default false; no effect on real builds).
      const skipOnboarding = bool.fromEnvironment('SKIP_ONBOARDING');
      final done = skipOnboarding ||
          ref.read(settingsControllerProvider).onboardingComplete;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!done && !atOnboarding) return Routes.onboarding;
      if (done && atOnboarding) return Routes.focus;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppScaffold(
          navigationShell: navigationShell,
          accessory: const ActiveSessionShelf(),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.focus,
                builder: (context, state) => const HomeScreen(),
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
        path: Routes.locationPicker,
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: Routes.eyeCareBreak,
        builder: (context, state) => const BreakScreen(),
      ),
      GoRoute(
        path: Routes.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: Routes.tasks,
        builder: (context, state) => const TodosScreen(),
      ),
      GoRoute(
        path: Routes.focusSession,
        builder: (context, state) => const FocusScreen(),
      ),
      GoRoute(
        path: Routes.alarmRinging,
        builder: (context, state) => const AlarmRingingScreen(
          item: AlarmItem(id: 'preview', hour: 6, minute: 30),
        ),
      ),
      GoRoute(
        path: Routes.alarmEditor,
        builder: (context, state) =>
            AlarmEditorScreen(existing: state.extra as AlarmItem?),
      ),
    ],
  );
});
