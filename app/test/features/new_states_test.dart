import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/core/widgets/progress_ring.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/alarm/presentation/alarm_ringing_screen.dart';
import 'package:tarf/features/focus/application/focus_controller.dart';
import 'package:tarf/features/focus/presentation/active_session_shelf.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(Widget child, SharedPreferences prefs) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('alarm-ringing modal shows the time, label, and actions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var stopped = false;
    var snoozed = false;

    await tester.pumpWidget(_host(
      AlarmRingingScreen(
        item: const AlarmItem(id: 'a', hour: 6, minute: 30, label: 'Fajr'),
        onStop: () => stopped = true,
        onSnooze: () => snoozed = true,
      ),
      prefs,
    ));
    await tester.pump();

    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);

    await tester.tap(find.text('Snooze'));
    expect(snoozed, isTrue);
    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
  });

  testWidgets('active-session shelf hides when idle and appears when running',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_host(const ActiveSessionShelf(), prefs));
    await tester.pump();

    // Idle: the shelf collapses to nothing (no ring).
    expect(find.byType(ProgressRing), findsNothing);

    // Start a focus session → the shelf reveals the running ring.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ActiveSessionShelf)),
    );
    container.read(focusControllerProvider.notifier).startWork();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ProgressRing), findsOneWidget);
  });
}
