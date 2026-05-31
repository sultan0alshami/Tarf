import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/core/active_time_tracker.dart';

ActiveTimeTracker makeTracker() => ActiveTimeTracker(
      idleThreshold: const Duration(minutes: 1),
      idleResetThreshold: const Duration(minutes: 5),
    );

void main() {
  group('ActiveTimeTracker', () {
    test('accumulates only active time and becomes due', () {
      final t = makeTracker();
      for (var i = 0; i < 20; i++) {
        t.tick(const Duration(minutes: 1), active: true);
      }
      expect(t.accumulated, const Duration(minutes: 20));
      expect(t.isDue(const Duration(minutes: 20)), isTrue);
      expect(t.isDue(const Duration(minutes: 21)), isFalse);
    });

    test('prolonged inactivity (>= reset) zeroes accumulation', () {
      final t = makeTracker();
      for (var i = 0; i < 10; i++) {
        t.tick(const Duration(minutes: 1), active: true);
      }
      for (var i = 0; i < 6; i++) {
        t.tick(const Duration(minutes: 1), active: false);
      }
      expect(t.accumulated, Duration.zero);
      expect(t.isPaused, isTrue);
    });

    test('brief inactivity pauses but preserves accumulation, then resumes', () {
      final t = makeTracker();
      for (var i = 0; i < 10; i++) {
        t.tick(const Duration(minutes: 1), active: true);
      }
      t.tick(const Duration(minutes: 1), active: false);
      t.tick(const Duration(minutes: 1), active: false); // 2 min idle < 5
      expect(t.accumulated, const Duration(minutes: 10));
      expect(t.isPaused, isTrue);

      t.tick(const Duration(minutes: 1), active: true);
      expect(t.isPaused, isFalse);
      expect(t.accumulated, const Duration(minutes: 11));
    });

    test('reset clears everything', () {
      final t = makeTracker()..tick(const Duration(minutes: 5), active: true);
      t.reset();
      expect(t.accumulated, Duration.zero);
      expect(t.isPaused, isFalse);
    });
  });
}
