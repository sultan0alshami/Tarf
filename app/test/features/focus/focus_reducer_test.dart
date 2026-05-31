import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/focus/domain/focus_models.dart';

void main() {
  const cfg = FocusConfig();

  FocusState work(Duration remaining, {int completed = 0}) => FocusState(
        phase: FocusPhase.work,
        remaining: remaining,
        totalForPhase: cfg.work,
        running: true,
        completedWorkSessions: completed,
      );

  group('advanceFocus', () {
    test('decrements remaining while running in a phase', () {
      final r = advanceFocus(work(const Duration(minutes: 25)), cfg,
          const Duration(minutes: 1));
      expect(r.phase, FocusPhase.work);
      expect(r.remaining, const Duration(minutes: 24));
      expect(r.justCompletedPhase, isNull);
    });

    test('completing work goes to a short break and counts the session', () {
      final r = advanceFocus(
          work(const Duration(minutes: 1)), cfg, const Duration(minutes: 1));
      expect(r.completedWorkSessions, 1);
      expect(r.phase, FocusPhase.shortBreak);
      expect(r.remaining, cfg.shortBreak);
      expect(r.running, isTrue); // autoStartBreaks default
      expect(r.justCompletedPhase, FocusPhase.work);
    });

    test('every 4th work session triggers a long break', () {
      final r = advanceFocus(work(const Duration(minutes: 1), completed: 3), cfg,
          const Duration(minutes: 1));
      expect(r.completedWorkSessions, 4);
      expect(r.phase, FocusPhase.longBreak);
      expect(r.remaining, cfg.longBreak);
    });

    test('completing a break returns to work and stops (autoStartWork=false)', () {
      final s = FocusState(
        phase: FocusPhase.shortBreak,
        remaining: const Duration(seconds: 30),
        totalForPhase: cfg.shortBreak,
        running: true,
      );
      final r = advanceFocus(s, cfg, const Duration(minutes: 1));
      expect(r.phase, FocusPhase.work);
      expect(r.remaining, cfg.work);
      expect(r.running, isFalse);
      expect(r.justCompletedPhase, FocusPhase.shortBreak);
    });

    test('paused state is unchanged by ticks (eye breaks can never advance it)', () {
      final paused = FocusState(
        phase: FocusPhase.work,
        remaining: const Duration(minutes: 10),
        totalForPhase: cfg.work,
        running: false,
      );
      final r = advanceFocus(paused, cfg, const Duration(minutes: 5));
      expect(r.remaining, const Duration(minutes: 10));
      expect(r.phase, FocusPhase.work);
    });

    test('idle state is unchanged', () {
      const idle = FocusState();
      final r = advanceFocus(idle, cfg, const Duration(minutes: 1));
      expect(r.phase, FocusPhase.idle);
    });

    test('progress is elapsed fraction of the phase', () {
      final s = work(const Duration(minutes: 20)); // 5 of 25 elapsed
      expect(s.progress, closeTo(0.2, 1e-9));
    });
  });
}
