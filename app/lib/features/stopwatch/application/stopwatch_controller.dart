import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class StopwatchData {
  const StopwatchData({
    this.elapsed = Duration.zero,
    this.running = false,
    this.laps = const [],
  });

  final Duration elapsed;
  final bool running;
  final List<Duration> laps;

  StopwatchData copyWith({
    Duration? elapsed,
    bool? running,
    List<Duration>? laps,
  }) =>
      StopwatchData(
        elapsed: elapsed ?? this.elapsed,
        running: running ?? this.running,
        laps: laps ?? this.laps,
      );
}

class StopwatchController extends Notifier<StopwatchData> {
  final _sw = Stopwatch();
  Timer? _ticker;

  @override
  StopwatchData build() {
    ref.onDispose(() => _ticker?.cancel());
    return const StopwatchData();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 73),
      (_) => state = state.copyWith(elapsed: _sw.elapsed),
    );
  }

  void start() {
    if (state.running) return;
    _sw.start();
    state = state.copyWith(running: true);
    _ensureTicker();
  }

  void stop() {
    if (!state.running) return;
    _sw.stop();
    state = state.copyWith(running: false, elapsed: _sw.elapsed);
  }

  void lap() {
    if (!state.running) return;
    state = state.copyWith(laps: [..._sortedRecent(_sw.elapsed)]);
  }

  List<Duration> _sortedRecent(Duration at) => [at, ...state.laps];

  void reset() {
    _sw
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    state = const StopwatchData();
  }
}

final stopwatchControllerProvider =
    NotifierProvider<StopwatchController, StopwatchData>(
  StopwatchController.new,
);
