import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/core/widgets/tarf_wheel_picker.dart';
import 'package:tarf/features/timer/application/saved_timers_controller.dart';
import 'package:tarf/features/timer/presentation/saved_timer_editor_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('new-timer editor shows the wheel and saves a SavedTimer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(prefs, const SavedTimerEditorScreen()));
    await tester.pumpAndSettle();

    // Reuses the calm wheel picker.
    expect(find.byType(TarfWheelPicker), findsOneWidget);

    // Save (a 5-minute default preset is selected initially).
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(savedTimersControllerProvider), hasLength(1));
  });
}
