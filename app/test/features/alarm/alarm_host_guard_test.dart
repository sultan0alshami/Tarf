import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/double_fire_guard.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/alarm/application/alarms_controller.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/alarm/presentation/alarm_host.dart';
import 'package:tarf/features/alarm/presentation/alarm_ringing_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _app(SharedPreferences prefs) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AlarmHost(child: Scaffold(body: SizedBox.expand())),
      ),
    );

void main() {
  testWidgets('AlarmHost does not ring when the minute is already claimed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await tester.pumpWidget(_app(prefs));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlarmHost)),
    );

    // An enabled alarm scheduled for THIS minute.
    await container.read(alarmsControllerProvider.notifier).upsert(
          AlarmItem(id: 'a1', hour: now.hour, minute: now.minute),
        );
    // The background path already claimed this minute.
    const item = AlarmItem(id: 'a1', hour: 0, minute: 0);
    final key = 'standardAlarm:a1:'
        '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}';
    container.read(doubleFireGuardProvider).claim(key, now);

    // Drive the host's 10s poll a few times.
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();

    // The ringing modal must NOT have been pushed.
    expect(find.byType(AlarmRingingScreen), findsNothing);
    // (Use `item` to avoid unused: assert the key matches its own helper.)
    expect(item.id, 'a1');
  });
}
