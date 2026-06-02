import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_haptics.dart';

void main() {
  group('AudioHaptics', () {
    test('fires when enabled, regardless of reduce-motion', () {
      final sink = RecordingHapticSink();
      final h = AudioHaptics(sink);
      h.cue(HapticKind.transition, enabled: true);
      expect(sink.events, [HapticKind.transition]);
    });

    test('does nothing when disabled', () {
      final sink = RecordingHapticSink();
      AudioHaptics(sink).cue(HapticKind.alarm, enabled: false);
      expect(sink.events, isEmpty);
    });

    test('alarm/timer use a heavier impact than a transition', () {
      final sink = RecordingHapticSink();
      AudioHaptics(sink)
        ..cue(HapticKind.transition, enabled: true)
        ..cue(HapticKind.alarm, enabled: true)
        ..cue(HapticKind.timerDone, enabled: true);
      expect(sink.events,
          [HapticKind.transition, HapticKind.alarm, HapticKind.timerDone]);
    });
  });
}
