// Private fields are assigned from public named constructor params so callers
// use clean names (audio:/haptics:) rather than underscore-prefixed ones.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import '../../../core/audio/audio_haptics.dart';
import '../../../core/audio/sound_catalog.dart';
import '../../../core/audio/sound_spec.dart';
import '../../../core/audio/tarf_audio_service.dart';
import '../domain/alarm_item.dart';

/// Owns the *sound + haptic* side of a ringing alarm, separate from the modal's
/// visuals. The alarm bell loops for [AlarmItem.ringDurationSeconds] (capped) or
/// until [stop]; a gentle haptic repeats on a fixed cadence in parallel.
class AlarmSoundController {
  AlarmSoundController({
    required TarfAudioService audio,
    AudioHaptics haptics = const AudioHaptics(),
  })  : _audio = audio,
        _haptics = haptics;

  final TarfAudioService _audio;
  final AudioHaptics _haptics;
  Timer? _hapticTimer;
  bool _ringing = false;

  bool get isRinging => _ringing;

  /// Max ring we will hold sound for, so a misconfigured value can't loop forever.
  static const _maxRing = Duration(minutes: 5);
  static const _hapticEvery = Duration(seconds: 2);

  Future<void> start(
    AlarmItem item, {
    required bool hapticEnabled,
    bool playThroughSilent = false,
  }) async {
    if (_ringing) return;
    _ringing = true;
    final base = SoundCatalog.byId(item.sound);
    final spec = SoundSpec.synth(base.id,
        role: SoundRole.alarm,
        layers: base.layers,
        defaultDuration: base.defaultDuration,
        gain: base.gain);
    final ring = Duration(seconds: item.ringDurationSeconds);
    final capped = ring > _maxRing ? _maxRing : ring;
    await _audio.play(spec,
        channel: AudioChannel.alarm,
        loop: true,
        duration: capped,
        playThroughSilent: playThroughSilent);
    if (hapticEnabled) {
      _haptics.cue(HapticKind.alarm, enabled: true);
      _hapticTimer = Timer.periodic(
        _hapticEvery,
        (_) => _haptics.cue(HapticKind.alarm, enabled: true),
      );
    }
  }

  Future<void> stop() async {
    _ringing = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    await _audio.stop(AudioChannel.alarm);
  }

  void dispose() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }
}
