import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

/// Renders the app without running the eye-care 1s ticker to completion
/// (Home shows a live countdown, so pumpAndSettle would never settle).
Future<void> bootSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('boots Arabic-first into an RTL shell with localized destinations',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'tarf.app_settings.v1':
          jsonEncode({'onboardingComplete': true, 'localeCode': 'ar'}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TarfApp(),
      ),
    );
    await bootSettle(tester);

    // Default locale is Arabic -> the Home destination label is localized.
    expect(find.text('الرئيسية'), findsWidgets); // "Home"
    final dir = Directionality.of(tester.element(find.text('الرئيسية').first));
    expect(dir, TextDirection.rtl);
  });
}
