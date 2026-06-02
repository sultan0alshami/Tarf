import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/domain/tasbih_state.dart';

void main() {
  group('TasbihState', () {
    test('increments and reports cycle position for target 33', () {
      var s = const TasbihState(dayKey: '2026-06-01', count: 0);
      for (var i = 0; i < 33; i++) {
        s = s.increment(target: 33);
      }
      expect(s.count, 33);
      expect(s.justCompletedCycle, isTrue); // landed exactly on a multiple
      expect(s.inCycle, 0); // 33 % 33
    });

    test('inCycle wraps after the target', () {
      const s = TasbihState(dayKey: 'd', count: 34);
      expect(s.cyclePositionFor(33), 1); // 34 % 33
    });

    test('reset zeroes the count', () {
      const s = TasbihState(dayKey: 'd', count: 50);
      expect(s.reset().count, 0);
    });

    test('round-trips through json', () {
      const s = TasbihState(dayKey: '2026-06-01', count: 7);
      final r = TasbihState.fromJson(s.toJson());
      expect(r.dayKey, '2026-06-01');
      expect(r.count, 7);
    });
  });
}
