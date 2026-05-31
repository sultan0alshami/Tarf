import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

void main() {
  testWidgets('every main screen renders and navigation works (EN)',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'tarf.app_settings.v1':
          jsonEncode({'onboardingComplete': true, 'localeCode': 'en'}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TarfApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Focus (home) is the start tab.
    expect(find.text('Start'), findsWidgets);

    // Visit each tab via the rail.
    for (final tab in ['Timer', 'Alarm', 'Stopwatch']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(find.text(tab), findsWidgets);
    }

    // Back to Focus.
    await tester.tap(find.text('Focus').first);
    await tester.pumpAndSettle();

    // Open Tasks from the Focus app bar.
    await tester.tap(find.byTooltip('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('No tasks yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Open Insights.
    await tester.tap(find.byTooltip('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('No data yet — start a focus session'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Open Settings -> Eye care, then Account & Sync.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Eye care'), findsWidgets);

    await tester.tap(find.text('Eye care'));
    await tester.pumpAndSettle();
    expect(find.text('Reminder interval'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account & Sync'));
    await tester.pumpAndSettle();
    expect(find.text('Export my data'), findsOneWidget);
  });
}
