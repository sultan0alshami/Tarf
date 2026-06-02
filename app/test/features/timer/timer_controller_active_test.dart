import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';
import 'package:tarf/features/timer/domain/saved_timer.dart';

void main() {
  group('TimerController.runSaved', () {
    test('loads a saved timer into the runner with its id/label/sound', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(timerControllerProvider.notifier).runSaved(
            const SavedTimer(
              id: 't9',
              label: 'Steep',
              duration: Duration(minutes: 2),
              soundId: 'calm',
            ),
          );
      final s = c.read(timerControllerProvider);
      expect(s.total, const Duration(minutes: 2));
      expect(s.remaining, const Duration(minutes: 2));
      expect(s.activeTimerId, 't9');
      expect(s.label, 'Steep');
      expect(s.soundId, 'calm');
      expect(s.running, isFalse); // loaded, not auto-started
    });

    test('setDuration clears the saved-timer identity (ad-hoc timer)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(timerControllerProvider.notifier)
        ..runSaved(const SavedTimer(
            id: 't1', label: 'X', duration: Duration(minutes: 1)))
        ..setDuration(const Duration(minutes: 5));
      final s = c.read(timerControllerProvider);
      expect(s.activeTimerId, isNull);
      expect(s.label, isEmpty);
    });
  });
}
