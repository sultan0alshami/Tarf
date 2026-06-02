import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/presentation/location_picker_screen.dart';
import 'package:tarf/features/prayer/application/geo_locator.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, GeoLocator geo) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        geoLocatorProvider.overrideWithValue(geo),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LocationPickerScreen(),
      ),
    );

void main() {
  testWidgets('choosing a method persists it to EyeCareConfig',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs, const UnavailableGeoLocator()));
    await tester.pumpAndSettle();

    // Open the method group and pick MWL.
    await tester.tap(find.text('Calculation method'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muslim World League'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocationPickerScreen)),
    );
    expect(container.read(eyeCareConfigProvider).prayerMethod,
        'muslimWorldLeague');
  });

  testWidgets('Use my location with no GPS keeps manual entry (no error wall)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs, const UnavailableGeoLocator()));
    await tester.pumpAndSettle();

    // The convenience button is hidden when geolocation is unsupported.
    expect(find.text('Use my location'), findsNothing);
    // Manual coordinate fields are present.
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
  });
}
