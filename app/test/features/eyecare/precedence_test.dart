import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/core/precedence.dart';

void main() {
  final t12 = DateTime(2026, 1, 1, 12);

  group('decideBreak', () {
    test('fires when everything is clear and the user is active', () {
      expect(decideBreak(SchedulerState.base(now: t12)), BreakDecision.fire);
    });

    test('global pause takes precedence over everything', () {
      final s = SchedulerState.base(now: t12).copyWith(
        globalPauseUntil: t12.add(const Duration(hours: 1)),
        isIdle: true,
        inPrayerWindow: true,
        prayerPauseEnabled: true,
      );
      expect(decideBreak(s), BreakDecision.suppressPaused);
    });

    test('expired global pause does not suppress', () {
      final s = SchedulerState.base(now: t12).copyWith(
        globalPauseUntil: t12.subtract(const Duration(minutes: 1)),
      );
      expect(decideBreak(s), BreakDecision.fire);
    });

    test('strict mode does not change firing (pause still wins)', () {
      // Strict is not part of SchedulerState — proving strict has no bearing on
      // whether a break fires; pause is what suppresses here.
      final s = SchedulerState.base(now: t12).copyWith(
        globalPauseUntil: t12.add(const Duration(minutes: 30)),
      );
      expect(decideBreak(s), BreakDecision.suppressPaused);
    });

    test('snooze suppresses when active and is below pause in precedence', () {
      final snoozed = SchedulerState.base(now: t12)
          .copyWith(snoozeUntil: t12.add(const Duration(minutes: 5)));
      expect(decideBreak(snoozed), BreakDecision.snoozed);

      final pausedAndSnoozed = snoozed.copyWith(
        globalPauseUntil: t12.add(const Duration(minutes: 5)),
      );
      expect(decideBreak(pausedAndSnoozed), BreakDecision.suppressPaused);
    });

    test('outside working hours suppresses', () {
      final s = SchedulerState.base(now: t12)
          .copyWith(workingHoursEnabled: true, withinWorkingHours: false);
      expect(decideBreak(s), BreakDecision.suppressWorkingHours);
    });

    test('working hours disabled never suppresses on that basis', () {
      final s = SchedulerState.base(now: t12)
          .copyWith(workingHoursEnabled: false, withinWorkingHours: false);
      expect(decideBreak(s), BreakDecision.fire);
    });

    test('prayer window suppresses when enabled', () {
      final s = SchedulerState.base(now: t12)
          .copyWith(prayerPauseEnabled: true, inPrayerWindow: true);
      expect(decideBreak(s), BreakDecision.suppressPrayer);
    });

    test('prayer window ignored when feature disabled', () {
      final s = SchedulerState.base(now: t12)
          .copyWith(prayerPauseEnabled: false, inPrayerWindow: true);
      expect(decideBreak(s), BreakDecision.fire);
    });

    test('screen off suppresses', () {
      expect(
        decideBreak(SchedulerState.base(now: t12).copyWith(isScreenOff: true)),
        BreakDecision.suppressScreenOff,
      );
    });

    test('idle suppresses', () {
      expect(
        decideBreak(SchedulerState.base(now: t12).copyWith(isIdle: true)),
        BreakDecision.suppressIdle,
      );
    });

    test('on call / media suppresses', () {
      expect(
        decideBreak(
            SchedulerState.base(now: t12).copyWith(isOnCallOrMedia: true)),
        BreakDecision.suppressMedia,
      );
    });

    test('active Pomodoro break suppresses the eye cue', () {
      expect(
        decideBreak(
            SchedulerState.base(now: t12).copyWith(pomodoroBreakActive: true)),
        BreakDecision.suppressPomodoro,
      );
    });

    test('DND suppresses only when respected and not loud-through-silence', () {
      final respected = SchedulerState.base(now: t12)
          .copyWith(dndActive: true, respectDnd: true);
      expect(decideBreak(respected), BreakDecision.suppressDnd);

      final loudOptIn = respected.copyWith(loudThroughSilence: true);
      expect(decideBreak(loudOptIn), BreakDecision.fire);

      final notRespected = respected.copyWith(respectDnd: false);
      expect(decideBreak(notRespected), BreakDecision.fire);
    });

    test('screen-off outranks idle and media when several apply', () {
      final s = SchedulerState.base(now: t12).copyWith(
        isScreenOff: true,
        isIdle: true,
        isOnCallOrMedia: true,
      );
      expect(decideBreak(s), BreakDecision.suppressScreenOff);
    });
  });
}
