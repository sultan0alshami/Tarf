import '../domain/dhikr.dart';

/// Plays the break audio so that the SOUND ending is the cue that the break is
/// over. The OS notification is only a visual cue; this app-played audio is what
/// makes "sound ends exactly when the 20s ends" true across platforms.
///
/// Sequence: a soft start chime, then the recitation (bundled clip or TTS) or
/// calm ambience for [duration], then a distinct end chime exactly at the end.
abstract interface class BreakAudioPlayer {
  /// Begins the break audio for [duration]. Returns immediately; the audio runs
  /// for the full duration. Honors [soundEnabled] (falls back to silence).
  Future<void> start({
    required Duration duration,
    required bool soundEnabled,
    Dhikr? dhikr,
  });

  /// Stops any playing break audio immediately (e.g. user skipped).
  Future<void> stop();

  /// Disposes underlying resources.
  Future<void> dispose();
}

/// No-op player used when sound is disabled or as a safe default before the
/// native audio backend is wired in. The visual countdown ring still drives the
/// break length.
class SilentBreakAudio implements BreakAudioPlayer {
  const SilentBreakAudio();

  @override
  Future<void> start({
    required Duration duration,
    required bool soundEnabled,
    Dhikr? dhikr,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Records calls for unit tests.
class FakeBreakAudio implements BreakAudioPlayer {
  int startCount = 0;
  int stopCount = 0;
  Duration? lastDuration;
  bool? lastSoundEnabled;
  Dhikr? lastDhikr;

  @override
  Future<void> start({
    required Duration duration,
    required bool soundEnabled,
    Dhikr? dhikr,
  }) async {
    startCount++;
    lastDuration = duration;
    lastSoundEnabled = soundEnabled;
    lastDhikr = dhikr;
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async {}
}
