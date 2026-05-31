import 'package:flutter/foundation.dart';

enum FocusPhase { idle, work, shortBreak, longBreak }

/// Configurable Pomodoro parameters. All durations are user-editable.
@immutable
class FocusConfig {
  const FocusConfig({
    this.work = const Duration(minutes: 25),
    this.shortBreak = const Duration(minutes: 5),
    this.longBreak = const Duration(minutes: 15),
    this.cyclesBeforeLongBreak = 4,
    this.autoStartBreaks = true,
    this.autoStartWork = false,
    this.dailyGoalSessions = 8,
  });

  final Duration work;
  final Duration shortBreak;
  final Duration longBreak;
  final int cyclesBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final int dailyGoalSessions;

  Duration durationFor(FocusPhase phase) => switch (phase) {
        FocusPhase.work => work,
        FocusPhase.shortBreak => shortBreak,
        FocusPhase.longBreak => longBreak,
        FocusPhase.idle => Duration.zero,
      };

  Map<String, Object?> toJson() => {
        'workS': work.inSeconds,
        'shortS': shortBreak.inSeconds,
        'longS': longBreak.inSeconds,
        'cyclesBeforeLong': cyclesBeforeLongBreak,
        'autoStartBreaks': autoStartBreaks,
        'autoStartWork': autoStartWork,
        'dailyGoalSessions': dailyGoalSessions,
      };

  factory FocusConfig.fromJson(Map<String, Object?> j) => FocusConfig(
        work: Duration(seconds: (j['workS'] as int?) ?? 1500),
        shortBreak: Duration(seconds: (j['shortS'] as int?) ?? 300),
        longBreak: Duration(seconds: (j['longS'] as int?) ?? 900),
        cyclesBeforeLongBreak: (j['cyclesBeforeLong'] as int?) ?? 4,
        autoStartBreaks: (j['autoStartBreaks'] as bool?) ?? true,
        autoStartWork: (j['autoStartWork'] as bool?) ?? false,
        dailyGoalSessions: (j['dailyGoalSessions'] as int?) ?? 8,
      );
}

/// Immutable snapshot of the focus timer.
@immutable
class FocusState {
  const FocusState({
    this.phase = FocusPhase.idle,
    this.remaining = Duration.zero,
    this.totalForPhase = Duration.zero,
    this.running = false,
    this.completedWorkSessions = 0,
    this.taskId,
    this.justCompletedPhase,
  });

  final FocusPhase phase;
  final Duration remaining;
  final Duration totalForPhase;
  final bool running;
  final int completedWorkSessions;
  final String? taskId;

  /// Set on the tick where a phase just finished (for chimes/haptics), else null.
  final FocusPhase? justCompletedPhase;

  /// 0..1 elapsed progress of the current phase (for the ring).
  double get progress {
    if (totalForPhase.inMilliseconds == 0) return 0;
    final elapsed = totalForPhase - remaining;
    return (elapsed.inMilliseconds / totalForPhase.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get isBreak => phase == FocusPhase.shortBreak || phase == FocusPhase.longBreak;

  FocusState copyWith({
    FocusPhase? phase,
    Duration? remaining,
    Duration? totalForPhase,
    bool? running,
    int? completedWorkSessions,
    String? taskId,
    bool clearTaskId = false,
    FocusPhase? justCompletedPhase,
    bool clearJustCompleted = false,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      totalForPhase: totalForPhase ?? this.totalForPhase,
      running: running ?? this.running,
      completedWorkSessions:
          completedWorkSessions ?? this.completedWorkSessions,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      justCompletedPhase:
          clearJustCompleted ? null : (justCompletedPhase ?? this.justCompletedPhase),
    );
  }
}

/// Pure transition: advances [s] by [delta] under [config], handling phase
/// completion and Pomodoro chaining. This is the single source of truth for the
/// focus timer's behavior and is fully unit-tested.
FocusState advanceFocus(FocusState s, FocusConfig config, Duration delta) {
  if (!s.running || s.phase == FocusPhase.idle) {
    return s.justCompletedPhase == null ? s : s.copyWith(clearJustCompleted: true);
  }

  final next = s.remaining - delta;
  if (next > Duration.zero) {
    return s.copyWith(remaining: next, clearJustCompleted: true);
  }

  // Current phase finished -> decide the next phase.
  final finished = s.phase;
  if (finished == FocusPhase.work) {
    final completed = s.completedWorkSessions + 1;
    final goLong = completed % config.cyclesBeforeLongBreak == 0;
    final nextPhase = goLong ? FocusPhase.longBreak : FocusPhase.shortBreak;
    final dur = config.durationFor(nextPhase);
    return s.copyWith(
      phase: nextPhase,
      remaining: dur,
      totalForPhase: dur,
      running: config.autoStartBreaks,
      completedWorkSessions: completed,
      justCompletedPhase: finished,
    );
  } else {
    // A break finished -> back to work.
    final dur = config.durationFor(FocusPhase.work);
    return s.copyWith(
      phase: FocusPhase.work,
      remaining: dur,
      totalForPhase: dur,
      running: config.autoStartWork,
      justCompletedPhase: finished,
    );
  }
}
