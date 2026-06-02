import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';

void main() {
  group('TimerController', () {
    test('setDuration resets total and remaining', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(timerControllerProvider.notifier)
          .setDuration(const Duration(minutes: 10));
      final s = container.read(timerControllerProvider);
      expect(s.total, const Duration(minutes: 10));
      expect(s.remaining, const Duration(minutes: 10));
      expect(s.running, isFalse);
    });

    test('addMinutes extends total when idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(timerControllerProvider.notifier)
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
      container.read(timerControllerProvider.notifier)
        ..setDuration(Duration.zero)
        ..start();
      expect(container.read(timerControllerProvider).running, isFalse);
    });
  });

  group('justFinished one-shot', () {
    test('is false before the timer reaches zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(timerControllerProvider.notifier).setDuration(const Duration(seconds: 2));
      expect(container.read(timerControllerProvider).justFinished, isFalse);
    });

    test('fires exactly on the zero-crossing tick, then clears next tick', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final c = container.read(timerControllerProvider.notifier)
          ..setDuration(const Duration(seconds: 1))
          ..start();
        async.elapse(const Duration(seconds: 1));
        final atZero = container.read(timerControllerProvider);
        expect(atZero.remaining, Duration.zero);
        expect(atZero.finished, isTrue);
        expect(atZero.justFinished, isTrue);
        // The screen will have consumed it; a controller acknowledge clears it.
        c.acknowledgeFinished();
        expect(container.read(timerControllerProvider).justFinished, isFalse);
        expect(container.read(timerControllerProvider).finished, isTrue);
      });
    });

    test('reset clears finished and justFinished', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(timerControllerProvider.notifier)
        ..setDuration(const Duration(seconds: 1));
      c.reset();
      final s = container.read(timerControllerProvider);
      expect(s.finished, isFalse);
      expect(s.justFinished, isFalse);
    });
  });
}
