import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/tarf_repository.dart';

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
}
