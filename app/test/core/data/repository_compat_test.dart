import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/repository_providers.dart';
import 'package:tarf/core/data/tarf_repository.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/alarm/application/alarms_controller.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';
import 'package:tarf/features/focus/application/focus_controller.dart';
import 'package:tarf/features/focus/domain/focus_models.dart';
import 'package:tarf/features/insights/application/progress_controller.dart';
import 'package:tarf/features/timer/application/saved_timers_controller.dart';
import 'package:tarf/features/timer/domain/saved_timer.dart';
import 'package:tarf/features/todos/application/todos_controller.dart';

void main() {
  test('StorageKey ids exactly match the legacy prefs keys', () {
    expect(StorageKey.settings.id, 'tarf.app_settings.v1');
    expect(StorageKey.eyecareConfig.id, 'tarf.eyecare_config.v1');
    expect(StorageKey.focusConfig.id, 'tarf.focus_config.v1');
    expect(StorageKey.progress.id, 'tarf.progress.v1');
    expect(StorageKey.todos.id, 'tarf.todos.v1');
    expect(StorageKey.alarms.id, 'tarf.alarms.v1');
    // P3 saved-timers: enum maps to the shipped key (NOT the reserved name).
    expect(StorageKey.timers.id, 'tarf.saved_timers.v1');
  });

  test('reads data written the OLD way (raw setString) unchanged', () async {
    SharedPreferences.setMockInitialValues({
      'tarf.app_settings.v1': jsonEncode({'localeCode': 'ar', 'onboardingComplete': true}),
    });
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    expect((repo.read(StorageKey.settings)! as Map)['localeCode'], 'ar');
  });

  test('writes data the OLD code can still read (same key + json)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);
    await repo.write(StorageKey.todos, {'list': <Object?>[]});
    // Legacy reader path:
    expect(prefs.getString('tarf.todos.v1'), jsonEncode({'list': <Object?>[]}));
  });

  // --- On-disk byte-compat per controller -----------------------------------
  //
  // The tests above only pin the StorageKey strings. These drive REAL data
  // through each refactored controller (over an in-memory SharedPreferences) and
  // assert the prefs key decodes to the exact legacy JSON envelope users already
  // have on disk. A future toJson() rename/reshape FAILS here instead of
  // silently corrupting on-disk compat across an app update.
  group('controllers persist the legacy on-disk JSON envelope', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(overrides: [
        // Route every controller's write through a PrefsRepository over the
        // SAME in-memory prefs we read back below.
        tarfRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
      ]);
    });

    tearDown(() => container.dispose());

    /// Decodes whatever the controller persisted under [key].
    Object? decode(StorageKey key) {
      final raw = prefs.getString(key.id);
      return raw == null ? null : jsonDecode(raw);
    }

    test('settings -> Map with the legacy field names', () async {
      await container
          .read(settingsControllerProvider.notifier)
          .setLocale('en');
      await container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await container
          .read(settingsControllerProvider.notifier)
          .completeOnboarding();

      final json = decode(StorageKey.settings)! as Map<String, Object?>;
      // Bare Map (not wrapped), carrying the AppSettings.toJson keys verbatim.
      expect(json['localeCode'], 'en');
      expect(json['themeMode'], 'dark');
      expect(json['onboardingComplete'], true);
      expect(json.keys, containsAll(<String>[
        'themeMode',
        'localeCode',
        'numeralSystem',
        'reduceMotion',
        'onboardingComplete',
        'notifPrimingShown',
      ]));
    });

    test('eyecare config -> Map with the legacy field names', () async {
      await container.read(eyeCareConfigProvider.notifier).update(
            const EyeCareConfig(
              eyeInterval: Duration(minutes: 30),
              soundEnabled: false,
              prayerLatitude: 21.4225,
              prayerLongitude: 39.8262,
            ),
          );

      final json = decode(StorageKey.eyecareConfig)! as Map<String, Object?>;
      // Durations persist as seconds under the short keys; not the field names.
      expect(json['eyeIntervalS'], 1800);
      expect(json['sound'], false);
      expect(json['prayerLat'], 21.4225);
      expect(json['prayerLng'], 39.8262);
      expect(json.keys, containsAll(<String>[
        'enabled',
        'eyeIntervalS',
        'eyeBreakS',
        'sound',
        'haptic',
        'prayerLat',
        'prayerLng',
        'prayerMethod',
        'prayerAlarms',
      ]));
    });

    test('focus config -> Map with the legacy field names', () async {
      await container.read(focusConfigProvider.notifier).update(
            const FocusConfig(
              work: Duration(minutes: 50),
              dailyGoalSessions: 6,
            ),
          );

      final json = decode(StorageKey.focusConfig)! as Map<String, Object?>;
      expect(json['workS'], 3000);
      expect(json['dailyGoalSessions'], 6);
      expect(json.keys, containsAll(<String>[
        'workS',
        'shortS',
        'longS',
        'cyclesBeforeLong',
        'autoStartBreaks',
        'autoStartWork',
        'dailyGoalSessions',
      ]));
    });

    test('progress -> day-keyed Map of Maps with the legacy field names', () async {
      final now = DateTime(2026, 6, 1, 10);
      await container
          .read(progressControllerProvider.notifier)
          .addFocusSession(now, 25);
      await container
          .read(progressControllerProvider.notifier)
          .addBreak(now, taken: true);

      final json = decode(StorageKey.progress)! as Map<String, Object?>;
      expect(json.keys.single, '2026-06-01');
      final day = json['2026-06-01']! as Map<String, Object?>;
      expect(day['fm'], 25); // focusMinutes
      expect(day['s'], 1); // sessions
      expect(day['bt'], 1); // breaksTaken
      expect(day.keys, containsAll(<String>['day', 'fm', 's', 'bt', 'bs']));
    });

    test('todos -> bare List whose elements carry the legacy fields', () async {
      await container
          .read(todosControllerProvider.notifier)
          .add('Read Quran', estimated: 2, nowMs: 1717200000000);

      final json = decode(StorageKey.todos)!;
      expect(json, isA<List<Object?>>()); // bare array, not wrapped in a Map
      final item = (json as List).single as Map<String, Object?>;
      expect(item['title'], 'Read Quran');
      expect(item['est'], 2); // estimatedSessions
      expect(item['ts'], 1717200000000); // createdAtMs
      expect(item.keys, containsAll(<String>[
        'id',
        'title',
        'done',
        'est',
        'act',
        'ts',
      ]));
    });

    test('alarms -> bare List whose elements carry the legacy fields', () async {
      await container.read(alarmsControllerProvider.notifier).upsert(
            const AlarmItem(
              id: 'a1',
              hour: 5,
              minute: 30,
              label: 'Fajr',
              days: {1, 2, 3},
            ),
          );

      final json = decode(StorageKey.alarms)!;
      expect(json, isA<List<Object?>>());
      final item = (json as List).single as Map<String, Object?>;
      expect(item['h'], 5);
      expect(item['m'], 30);
      expect(item['label'], 'Fajr');
      expect(item['days'], [1, 2, 3]);
      expect(item.keys, containsAll(<String>[
        'id',
        'h',
        'm',
        'label',
        'on',
        'days',
        'snd',
        'rds',
        'snz',
      ]));
    });

    test('saved timers -> bare List whose elements carry the legacy fields', () async {
      await container.read(savedTimersControllerProvider.notifier).upsert(
            const SavedTimer(
              id: 's1',
              label: 'Tea',
              duration: Duration(minutes: 3),
              soundId: 'chime',
            ),
          );

      final json = decode(StorageKey.timers)!;
      expect(json, isA<List<Object?>>());
      final item = (json as List).single as Map<String, Object?>;
      expect(item['id'], 's1');
      expect(item['label'], 'Tea');
      expect(item['durS'], 180); // duration in seconds
      expect(item['snd'], 'chime'); // soundId
      expect(item.keys, containsAll(<String>['id', 'label', 'durS', 'snd']));
    });
  });
}
