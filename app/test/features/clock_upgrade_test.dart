import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/format/numerals.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/core/widgets/tarf_wheel_picker.dart';
import 'package:tarf/features/alarm/application/alarm_derived.dart';
import 'package:tarf/features/alarm/application/alarms_controller.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/theme/app_theme.dart';

ProviderContainer _container(SharedPreferences prefs) => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

void main() {
  test('AlarmItem round-trips the new editor fields', () {
    const a = AlarmItem(
      id: 'x',
      hour: 6,
      minute: 30,
      sound: 'bell',
      ringDurationSeconds: 120,
      snoozeMinutes: 10,
    );
    final back = AlarmItem.fromJson(a.toJson());
    expect(back.hour, 6);
    expect(back.sound, 'bell');
    expect(back.ringDurationSeconds, 120);
    expect(back.snoozeMinutes, 10);
  });

  test('prayerAlarmsProvider yields the five daily prayers, enabled by default',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _container(prefs);
    addTearDown(c.dispose);

    final prayers = c.read(prayerAlarmsProvider);
    expect(
      prayers.map((p) => p.id).toList(),
      ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'],
    );
    expect(prayers.every((p) => p.enabled), isTrue);
  });

  test('AlarmsController.upsert adds then replaces by id', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _container(prefs);
    addTearDown(c.dispose);
    final notifier = c.read(alarmsControllerProvider.notifier);

    await notifier.upsert(const AlarmItem(id: 'a1', hour: 7, minute: 0));
    expect(c.read(alarmsControllerProvider).length, 1);

    await notifier.upsert(const AlarmItem(id: 'a1', hour: 8, minute: 15));
    final list = c.read(alarmsControllerProvider);
    expect(list.length, 1);
    expect(list.single.hour, 8);
    expect(list.single.minute, 15);
  });

  test('nextAlarmProvider returns a duration within a day for a daily alarm',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _container(prefs);
    addTearDown(c.dispose);

    await c.read(alarmsControllerProvider.notifier).upsert(
          const AlarmItem(
            id: 'd',
            hour: 7,
            minute: 0,
            days: {1, 2, 3, 4, 5, 6, 7},
          ),
        );
    final next = c.read(nextAlarmProvider);
    expect(next, isNotNull);
    expect(next! <= const Duration(days: 1), isTrue);
  });

  testWidgets('TarfWheelPicker renders its selected value', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: TarfTheme.dark(),
      home: Scaffold(
        body: TarfWheelPicker(
          columns: [
            TarfWheelColumn(
              values: [
                for (var i = 0; i < 10; i++)
                  Numerals.padded(i, NumeralSystem.western),
              ],
              selected: 5,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('05'), findsOneWidget);
  });
}
