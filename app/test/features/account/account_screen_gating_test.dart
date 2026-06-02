import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/repository_providers.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/account/application/account_controller.dart';
import 'package:tarf/features/account/application/auth_service.dart';
import 'package:tarf/features/account/presentation/account_screen.dart';
import 'package:tarf/firebase/firebase_flags.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Future<Widget> _host({required bool cloud}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = PrefsRepository(prefs);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tarfRepositoryProvider.overrideWithValue(repo),
      firebaseFlagsProvider.overrideWithValue(
          FirebaseFlags(configPresent: cloud, compileEnabled: cloud)),
      authServiceProvider.overrideWithValue(FakeAuthService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: TarfTheme.light(),
      home: const AccountScreen(),
    ),
  );
}

void main() {
  testWidgets('sign-in buttons are DISABLED when cloud flag is off', (tester) async {
    await tester.pumpWidget(await _host(cloud: false));
    await tester.pump();
    final google = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Continue with Google'), matching: find.byType(OutlinedButton)));
    expect(google.onPressed, isNull); // disabled
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('sign-in buttons are ENABLED when cloud flag is on', (tester) async {
    await tester.pumpWidget(await _host(cloud: true));
    await tester.pump();
    final google = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Continue with Google'), matching: find.byType(OutlinedButton)));
    expect(google.onPressed, isNotNull); // enabled
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('export + delete-all rows are present in BOTH states', (tester) async {
    await tester.pumpWidget(await _host(cloud: false));
    await tester.pump();
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Delete all my data'), findsWidgets);
  });
}
