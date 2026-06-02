import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/saved_timer.dart';
import '../domain/timer_sound_catalog.dart';

@immutable
class CountdownData {
  const CountdownData({
    required this.total,
    required this.remaining,
    this.running = false,
    this.finished = false,
    this.justFinished = false,
    this.activeTimerId,
    this.label = '',
    this.soundId = kDefaultTimerSoundId,
  });

  final Duration total;
  final Duration remaining;
  final bool running;
  final bool finished;

  /// One-shot: true only on the tick that crossed zero, cleared by
  /// [TimerController.acknowledgeFinished] / the next tick / a reset. The screen
  /// consumes it to fire the completion sound + haptic exactly once.
  final bool justFinished;

  /// Identity of the saved timer currently loaded into the runner; null for an
  /// ad-hoc (wheel-set) countdown.
  final String? activeTimerId;

  /// Name of the active saved timer ('' = unnamed / ad-hoc).
  final String label;

  /// Sound id used for the completion cue (from the saved timer or default).
  final String soundId;

  double get progress {
    if (total.inMilliseconds == 0) return 0;
    return (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  CountdownData copyWith({
    Duration? total,
    Duration? remaining,
    bool? running,
    bool? finished,
    bool? justFinished,
    String? activeTimerId,
    bool clearIdentity = false,
    String? label,
    String? soundId,
  }) =>
      CountdownData(
        total: total ?? this.total,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
        finished: finished ?? this.finished,
        justFinished: justFinished ?? this.justFinished,
        activeTimerId:
            clearIdentity ? null : (activeTimerId ?? this.activeTimerId),
        label: clearIdentity ? '' : (label ?? this.label),
        soundId: soundId ?? this.soundId,
      );
}

class TimerController extends Notifier<CountdownData> {
  Timer? _ticker;

  @override
  CountdownData build() {
    ref.onDispose(() => _ticker?.cancel());
    const d = Duration(minutes: 5);
    return const CountdownData(total: d, remaining: d);
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.running) return;
    final next = state.remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      state = state.copyWith(
        remaining: Duration.zero,
        running: false,
        finished: true,
        justFinished: true,
      );
    } else {
      state = state.copyWith(remaining: next, justFinished: false);
    }
  }

  /// Clears the one-shot [CountdownData.justFinished] after the screen reacts.
  void acknowledgeFinished() {
    if (state.justFinished) state = state.copyWith(justFinished: false);
  }

  void setDuration(Duration d) {
    _ticker?.cancel();
    _ticker = null;
    state = CountdownData(total: d, remaining: d); // identity cleared (defaults)
  }

  /// Loads [t] into the single runner (replacing any active timer). Does not
  /// auto-start; the user taps Start, matching the existing idle->active flow.
  void runSaved(SavedTimer t) {
    _ticker?.cancel();
    _ticker = null;
    state = CountdownData(
      total: t.duration,
      remaining: t.duration,
      activeTimerId: t.id,
      label: t.label,
      soundId: t.soundId,
    );
  }

  void addMinutes(int minutes) {
    final total = state.total + Duration(minutes: minutes);
    final remaining = state.running
        ? state.remaining + Duration(minutes: minutes)
        : total;
    state = state.copyWith(
      total: total < Duration.zero ? Duration.zero : total,
      remaining: remaining < Duration.zero ? Duration.zero : remaining,
      finished: false,
    );
  }

  void start() {
    if (state.remaining <= Duration.zero) return;
    state = state.copyWith(running: true, finished: false, justFinished: false);
    _ensureTicker();
  }

  void pause() => state = state.copyWith(running: false);

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = CountdownData(total: state.total, remaining: state.total);
  }
}

final timerControllerProvider =
    NotifierProvider<TimerController, CountdownData>(TimerController.new);
