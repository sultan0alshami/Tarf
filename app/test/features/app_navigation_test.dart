import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

// Bounded pump (Home's live countdown means pumpAndSettle never settles).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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
    await settle(tester);

    // Home (first tab) leads with eye-care + the Start-focus CTA.
    expect(find.text('Start focus session'), findsOneWidget);
    expect(find.text('Next eye break'), findsOneWidget);

    // Visit each tab via the rail/bar.
    for (final tab in ['Timer', 'Alarm', 'Stopwatch']) {
      await tester.tap(find.text(tab).first);
      await settle(tester);
      expect(find.text(tab), findsWidgets);
    }
    await tester.tap(find.text('Home').first);
    await settle(tester);

    // Tasks + Insights from the Home app bar.
    await tester.tap(find.byTooltip('Tasks'));
    await settle(tester);
    expect(find.text("We're here whenever you need a moment"), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.byTooltip('Insights'));
    await settle(tester);
    expect(find.text('Eye rests today'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    // Settings -> eye-care detail, then Account.
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    expect(find.text('Eye-care'), findsWidgets);

    await tester.tap(find.text('More eye-care settings'));
    await settle(tester);
    expect(find.text('Reminder interval'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    // Account row is the last item in a long, lazily-built list — scroll to it.
    await tester.scrollUntilVisible(
      find.text('Account'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    await tester.tap(find.text('Account'));
    await settle(tester);
    expect(find.text('Export my data'), findsOneWidget);
  });
}
