import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/permissions/presentation/notification_priming_sheet.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
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
  testWidgets('shows honest rationale and returns true on Enable',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    PrimingChoice? result;

    await tester.pumpWidget(_host(
      prefs,
      Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () async =>
              result = await showNotificationPrimingSheet(context),
          child: const Text('open'),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Honest body present.
    expect(find.textContaining('only while open'), findsOneWidget);
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    expect(result, PrimingChoice.enable);
  });

  testWidgets('returns notNow on Not now', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    PrimingChoice? result;
    await tester.pumpWidget(_host(
      prefs,
      Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () async =>
              result = await showNotificationPrimingSheet(context),
          child: const Text('open'),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, PrimingChoice.notNow);
  });
}
