import 'package:flutter/foundation.dart';

/// Which tier of break is due.
enum BreakKind { eyeMicro, longBreak }

/// The outcome of evaluating whether a break should fire right now. Exactly one
/// reason is returned, following a fixed precedence so behavior is deterministic
/// and testable.
enum BreakDecision {
  fire,
  suppressPaused,
  snoozed,
  suppressWorkingHours,
  suppressPrayer,
  suppressScreenOff,
  suppressIdle,
  suppressMedia,
  suppressPomodoro,
  suppressDnd,
}

/// Pure, serializable snapshot of everything that influences the decision.
///
/// This is the single input to [decideBreak]; keeping it pure makes the
/// reminder-precedence logic fully unit-testable without platform plumbing.
@immutable
class SchedulerState {
  const SchedulerState({
    required this.now,
    this.isScreenOff = false,
    this.isIdle = false,
    this.isOnCallOrMedia = false,
    this.globalPauseUntil,
    this.snoozeUntil,
    this.workingHoursEnabled = false,
    this.withinWorkingHours = true,
    this.prayerPauseEnabled = false,
    this.inPrayerWindow = false,
    this.pomodoroBreakActive = false,
    this.mergeWithPomodoro = false,
    this.dndActive = false,
    this.respectDnd = true,
    this.loudThroughSilence = false,
  });

  /// A convenient all-clear base for tests; override fields with [copyWith].
  factory SchedulerState.base({DateTime? now}) =>
      SchedulerState(now: now ?? DateTime(2026, 1, 1, 12));

  final DateTime now;
  final bool isScreenOff;
  final bool isIdle;
  final bool isOnCallOrMedia;
  final DateTime? globalPauseUntil;
  final DateTime? snoozeUntil;
  final bool workingHoursEnabled;
  final bool withinWorkingHours;
  final bool prayerPauseEnabled;
  final bool inPrayerWindow;
  final bool pomodoroBreakActive;
  final bool mergeWithPomodoro;
  final bool dndActive;
  final bool respectDnd;
  final bool loudThroughSilence;

  SchedulerState copyWith({
    DateTime? now,
    bool? isScreenOff,
    bool? isIdle,
    bool? isOnCallOrMedia,
    DateTime? globalPauseUntil,
    bool clearGlobalPause = false,
    DateTime? snoozeUntil,
    bool clearSnooze = false,
    bool? workingHoursEnabled,
    bool? withinWorkingHours,
    bool? prayerPauseEnabled,
    bool? inPrayerWindow,
    bool? pomodoroBreakActive,
    bool? mergeWithPomodoro,
    bool? dndActive,
    bool? respectDnd,
    bool? loudThroughSilence,
  }) {
    return SchedulerState(
      now: now ?? this.now,
      isScreenOff: isScreenOff ?? this.isScreenOff,
      isIdle: isIdle ?? this.isIdle,
      isOnCallOrMedia: isOnCallOrMedia ?? this.isOnCallOrMedia,
      globalPauseUntil:
          clearGlobalPause ? null : (globalPauseUntil ?? this.globalPauseUntil),
      snoozeUntil: clearSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
      workingHoursEnabled: workingHoursEnabled ?? this.workingHoursEnabled,
      withinWorkingHours: withinWorkingHours ?? this.withinWorkingHours,
      prayerPauseEnabled: prayerPauseEnabled ?? this.prayerPauseEnabled,
      inPrayerWindow: inPrayerWindow ?? this.inPrayerWindow,
      pomodoroBreakActive: pomodoroBreakActive ?? this.pomodoroBreakActive,
      mergeWithPomodoro: mergeWithPomodoro ?? this.mergeWithPomodoro,
      dndActive: dndActive ?? this.dndActive,
      respectDnd: respectDnd ?? this.respectDnd,
      loudThroughSilence: loudThroughSilence ?? this.loudThroughSilence,
    );
  }
}

/// Decides whether an eye break should fire now. Precedence (highest first):
///
/// 1. Global pause active        -> [BreakDecision.suppressPaused]
/// 2. Snooze active              -> [BreakDecision.snoozed]
/// 3. Outside working hours      -> [BreakDecision.suppressWorkingHours]
/// 4. Inside a prayer window     -> [BreakDecision.suppressPrayer]
/// 5. Screen off                 -> [BreakDecision.suppressScreenOff]
/// 6. User idle                  -> [BreakDecision.suppressIdle]
/// 7. On a call / media playing  -> [BreakDecision.suppressMedia]
/// 8. Already on a Pomodoro break-> [BreakDecision.suppressPomodoro]
/// 9. DND active and respected   -> [BreakDecision.suppressDnd]
/// otherwise                      -> [BreakDecision.fire]
///
/// Note: Strict mode does NOT affect whether a break fires — it only controls
/// whether the user may skip/finish early once the break is shown.
BreakDecision decideBreak(SchedulerState s) {
  final pauseUntil = s.globalPauseUntil;
  if (pauseUntil != null && s.now.isBefore(pauseUntil)) {
    return BreakDecision.suppressPaused;
  }

  final snoozeUntil = s.snoozeUntil;
  if (snoozeUntil != null && s.now.isBefore(snoozeUntil)) {
    return BreakDecision.snoozed;
  }

  if (s.workingHoursEnabled && !s.withinWorkingHours) {
    return BreakDecision.suppressWorkingHours;
  }

  if (s.prayerPauseEnabled && s.inPrayerWindow) {
    return BreakDecision.suppressPrayer;
  }

  if (s.isScreenOff) return BreakDecision.suppressScreenOff;
  if (s.isIdle) return BreakDecision.suppressIdle;
  if (s.isOnCallOrMedia) return BreakDecision.suppressMedia;

  // Already resting on a Pomodoro break: don't stack an eye break on top.
  if (s.pomodoroBreakActive) return BreakDecision.suppressPomodoro;

  // DND only suppresses when respected and the user hasn't opted into
  // loud-through-silence.
  if (s.dndActive && s.respectDnd && !s.loudThroughSilence) {
    return BreakDecision.suppressDnd;
  }

  return BreakDecision.fire;
}
