import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';

void main() {
  group('TimerController', () {
    test('setDuration resets total and remaining', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(timerControllerProvider.notifier);

      c.setDuration(const Duration(minutes: 10));
      final s = container.read(timerControllerProvider);
      expect(s.total, const Duration(minutes: 10));
      expect(s.remaining, const Duration(minutes: 10));
      expect(s.running, isFalse);
    });

    test('addMinutes extends total when idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(timerControllerProvider.notifier)
        ..setDuration(const Duration(minutes: 5))
        ..addMinutes(3);
      expect(container.read(timerControllerProvider).total,
          const Duration(minutes: 8));
    });

    test('progress reflects remaining fraction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(timerControllerProvider.notifier).setDuration(
            const Duration(minutes: 4),
          );
      expect(container.read(timerControllerProvider).progress, 1.0);
    });

    test('start is a no-op at zero remaining', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(timerControllerProvider.notifier)
        ..setDuration(Duration.zero)
        ..start();
      expect(container.read(timerControllerProvider).running, isFalse);
    });
  });
}
