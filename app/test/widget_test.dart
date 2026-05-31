import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/app.dart';
import 'package:tarf/core/settings/settings_controller.dart';

void main() {
  testWidgets('boots Arabic-first into an RTL shell with localized destinations',
      (tester) async {
    // Mark onboarding complete so the app boots straight to the shell.
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
    await tester.pumpAndSettle();

    // Default locale is Arabic -> the destination label is localized in Arabic.
    expect(find.text('التركيز'), findsWidgets); // "Focus"

    // ...and the whole tree is right-to-left.
    final dir = Directionality.of(tester.element(find.text('التركيز').first));
    expect(dir, TextDirection.rtl);
  });
}
