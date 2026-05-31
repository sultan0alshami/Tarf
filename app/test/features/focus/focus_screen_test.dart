import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

void main() {
  testWidgets('Focus home reflects the configured work duration', (tester) async {
    // Persist a 20-minute focus work duration; the home must show 20:00.
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
    await tester.pumpAndSettle();

    expect(find.text('20:00'), findsOneWidget);

    // The inline durations editor opens from the home (no Settings trip).
    await tester.tap(find.byTooltip('Edit durations'));
    await tester.pumpAndSettle();
    expect(find.text('Edit durations'), findsOneWidget);
  });
}
