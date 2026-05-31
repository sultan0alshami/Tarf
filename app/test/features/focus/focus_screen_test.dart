import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

// Bounded pump — never run the running focus/eye-care timers to settle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('Start focus opens a full-screen session at the configured duration',
      (tester) async {
    // Persist a 20-minute focus work duration; the session must show 20:00.
    SharedPreferences.setMockInitialValues({
      'tarf.app_settings.v1':
          jsonEncode({'onboardingComplete': true, 'localeCode': 'en'}),
      'tarf.focus_config.v1': jsonEncode({'workS': 1200}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TarfApp(),
      ),
    );
    await settle(tester);

    // From Home, start a focus session (pushes the full-screen Pomodoro).
    await tester.tap(find.text('Start focus session'));
    await settle(tester);

    expect(find.text('20:00'), findsOneWidget);

    // The inline durations editor opens from the session screen.
    await tester.tap(find.byTooltip('Edit durations'));
    await settle(tester);
    expect(find.text('Edit durations'), findsOneWidget);
  });
}
