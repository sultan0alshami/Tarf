import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class CountdownData {
  const CountdownData({
    required this.total,
    required this.remaining,
    this.running = false,
    this.finished = false,
    this.justFinished = false,
  });

  final Duration total;
  final Duration remaining;
  final bool running;
  final bool finished;

  /// One-shot: true only on the tick that crossed zero, cleared by
  /// [TimerController.acknowledgeFinished] / the next tick / a reset. The screen
  /// consumes it to fire the completion sound + haptic exactly once.
  final bool justFinished;

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
  }) =>
      CountdownData(
        total: total ?? this.total,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
        finished: finished ?? this.finished,
        justFinished: justFinished ?? this.justFinished,
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
    state = CountdownData(total: d, remaining: d);
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
