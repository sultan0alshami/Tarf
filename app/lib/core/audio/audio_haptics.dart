import 'package:flutter/services.dart';

/// Why a haptic is firing — selects an intensity and lets tests assert intent.
enum HapticKind { transition, alarm, timerDone, breakEnd }

/// Indirection over [HapticFeedback] so haptics are unit-testable.
abstract interface class HapticSink {
  void impact(HapticKind kind);
}

/// Production sink: maps each kind to a Flutter haptic primitive.
class PlatformHapticSink implements HapticSink {
  const PlatformHapticSink();
  @override
  void impact(HapticKind kind) {
    switch (kind) {
      case HapticKind.alarm:
      case HapticKind.timerDone:
        HapticFeedback.heavyImpact();
      case HapticKind.breakEnd:
        HapticFeedback.mediumImpact();
      case HapticKind.transition:
        HapticFeedback.selectionClick();
    }
  }
}

/// Records events for tests.
class RecordingHapticSink implements HapticSink {
  final List<HapticKind> events = [];
  @override
  void impact(HapticKind kind) => events.add(kind);
}

/// The equal-to-audio haptic cue. Honors only the user's haptics flag — it is
/// INDEPENDENT of reduce-motion (per Tarf accessibility rules).
class AudioHaptics {
  const AudioHaptics([this._sink = const PlatformHapticSink()]);
  final HapticSink _sink;

  void cue(HapticKind kind, {required bool enabled}) {
    if (!enabled) return;
    _sink.impact(kind);
  }
}
