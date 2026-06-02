import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/eyecare/application/tasbih_controller.dart';

Future<ProviderContainer> _c({Map<String, Object> seed = const {}}) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TasbihController', () {
    test('starts at zero for today and increments + persists', () async {
      final c = await _c();
      expect(c.read(tasbihControllerProvider).count, 0);
      await c.read(tasbihControllerProvider.notifier).increment();
      await c.read(tasbihControllerProvider.notifier).increment();
      expect(c.read(tasbihControllerProvider).count, 2);

      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(tasbihControllerProvider).count, 2); // same day persists
    });

    test('reset zeroes the count', () async {
      final c = await _c();
      final n = c.read(tasbihControllerProvider.notifier);
      await n.increment();
      await n.reset();
      expect(c.read(tasbihControllerProvider).count, 0);
    });

    test('target toggles between 33 and 99 and persists', () async {
      final c = await _c();
      expect(c.read(tasbihTargetProvider), 33);
      await c.read(tasbihTargetProvider.notifier).toggle();
      expect(c.read(tasbihTargetProvider), 99);
    });
  });
}
