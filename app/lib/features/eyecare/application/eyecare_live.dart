import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live, observable eye-care engine state so Home can show "next break in MM:SS"
/// and a progress sliver. The engine host (EyeCareHost) pushes [accumulated]
/// every tick; Home derives the remaining time from the configured interval.
@immutable
class EyeCareLiveState {
  const EyeCareLiveState({this.accumulated = Duration.zero, this.paused = false});

  final Duration accumulated;
  final bool paused;

  EyeCareLiveState copyWith({Duration? accumulated, bool? paused}) =>
      EyeCareLiveState(
        accumulated: accumulated ?? this.accumulated,
        paused: paused ?? this.paused,
      );
}

class EyeCareLive extends Notifier<EyeCareLiveState> {
  @override
  EyeCareLiveState build() => const EyeCareLiveState();

  void setAccumulated(Duration d) {
    if (d != state.accumulated) state = state.copyWith(accumulated: d);
  }

  void togglePause() => state = state.copyWith(paused: !state.paused);

  void reset() => state = const EyeCareLiveState();
}

final eyeCareLiveProvider =
    NotifierProvider<EyeCareLive, EyeCareLiveState>(EyeCareLive.new);
