import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/timer/application/saved_timers_controller.dart';
import 'package:tarf/features/timer/domain/saved_timer.dart';

Future<ProviderContainer> _c() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SavedTimersController', () {
    test('starts empty', () async {
      final c = await _c();
      expect(c.read(savedTimersControllerProvider), isEmpty);
    });

    test('upsert adds then edits the same id; persists across rebuild',
        () async {
      final c = await _c();
      final n = c.read(savedTimersControllerProvider.notifier);
      await n.upsert(const SavedTimer(
          id: 't1', label: 'Tea', duration: Duration(minutes: 3)));
      expect(c.read(savedTimersControllerProvider).length, 1);

      await n.upsert(const SavedTimer(
          id: 't1', label: 'Green tea', duration: Duration(minutes: 4)));
      expect(c.read(savedTimersControllerProvider).single.label, 'Green tea');

      // Re-read from storage with a fresh container -> persisted.
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(savedTimersControllerProvider).single.duration,
          const Duration(minutes: 4));
    });

    test('remove deletes by id', () async {
      final c = await _c();
      final n = c.read(savedTimersControllerProvider.notifier);
      await n.upsert(const SavedTimer(
          id: 'a', label: 'A', duration: Duration(minutes: 1)));
      await n.upsert(const SavedTimer(
          id: 'b', label: 'B', duration: Duration(minutes: 2)));
      await n.remove('a');
      expect(c.read(savedTimersControllerProvider).map((t) => t.id), ['b']);
    });
  });
}
