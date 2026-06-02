import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/timer/application/saved_timers_controller.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';
import 'package:tarf/features/timer/domain/saved_timer.dart';
import 'package:tarf/features/timer/presentation/timer_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

void main() {
  testWidgets('tapping a saved timer loads it into the runner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container
        .read(savedTimersControllerProvider.notifier)
        .upsert(const SavedTimer(
            id: 't1', label: 'Tea', duration: Duration(minutes: 3)));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TimerScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tea'), findsOneWidget);
    // The saved list sits below the fold in the test viewport; scroll it in.
    await tester.ensureVisible(find.text('Tea'));
    await tester.pump();
    await tester.tap(find.text('Tea'));
    await tester.pump();

    expect(container.read(timerControllerProvider).activeTimerId, 't1');
    expect(container.read(timerControllerProvider).total,
        const Duration(minutes: 3));

    // Cancel the runner's periodic ticker so no timer is pending at teardown.
    container.read(timerControllerProvider.notifier).reset();
    await tester.pump();
  });
}
