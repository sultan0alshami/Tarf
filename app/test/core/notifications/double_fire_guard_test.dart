import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/double_fire_guard.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first claim wins, second for same key is a no-op', () async {
    final prefs = await SharedPreferences.getInstance();
    final guard = DoubleFireGuard(prefs);
    final now = DateTime(2026, 6, 1, 6, 30);
    expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isTrue);
    expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isFalse);
  });

  test('different minutes are independent claims', () async {
    final prefs = await SharedPreferences.getInstance();
    final guard = DoubleFireGuard(prefs);
    final now = DateTime(2026, 6, 1, 6, 30);
    expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isTrue);
    expect(guard.claim('standardAlarm:a1:2026-06-01-06-31', now), isTrue);
  });

  test('claims persist across guard instances (same prefs)', () async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 6, 1, 6, 30);
    expect(DoubleFireGuard(prefs).claim('k', now), isTrue);
    expect(DoubleFireGuard(prefs).claim('k', now), isFalse); // remembered
  });

  test('claims older than 24h are pruned on the next claim', () async {
    final prefs = await SharedPreferences.getInstance();
    final guard = DoubleFireGuard(prefs);
    final old = DateTime(2026, 6, 1, 6, 30);
    guard.claim('old-key', old);
    // 25h later, a new claim prunes the stale entry; re-claiming old-key works.
    final later = old.add(const Duration(hours: 25));
    guard.claim('fresh', later);
    expect(guard.claim('old-key', later), isTrue); // pruned -> claimable again
  });
}
