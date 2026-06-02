import 'package:flutter/foundation.dart';

import 'sound_spec.dart';

/// Independent playback lanes so e.g. a focus chime and a break bed don't fight.
/// Each channel owns at most one active sound at a time.
enum AudioChannel { alarm, timer, focus, breakBed, breakCue, preview }

/// The single audio contract every feature depends on. Implemented by
/// [SilentAudioService] (default/disabled), [FakeAudioService] (tests), and the
/// real `JustAudioService`. Phase 2/3 depend ONLY on this interface.
abstract interface class TarfAudioService {
  /// Plays [spec] on [channel]. When [loop] is true the sound repeats until
  /// [stop]/[stopAll] (or, if [duration] is given, auto-stops after it).
  /// [playThroughSilent] requests the OS "play even in silent mode" category.
  /// Returns false if playback was blocked (e.g. web autoplay) so callers can
  /// fall back to the visual cue.
  Future<bool> play(
    SoundSpec spec, {
    required AudioChannel channel,
    bool loop = false,
    Duration? duration,
    bool playThroughSilent = false,
  });

  /// Stops the sound on [channel] (no-op if idle).
  Future<void> stop(AudioChannel channel);

  /// Stops every channel.
  Future<void> stopAll();

  /// Whether [channel] currently has an active sound.
  bool isPlaying(AudioChannel channel);

  /// Releases underlying resources.
  Future<void> dispose();
}

/// No-op implementation: safe default and the value when sound is disabled.
class SilentAudioService implements TarfAudioService {
  const SilentAudioService();
  @override
  Future<bool> play(SoundSpec spec,
          {required AudioChannel channel,
          bool loop = false,
          Duration? duration,
          bool playThroughSilent = false}) async =>
      false;
  @override
  Future<void> stop(AudioChannel channel) async {}
  @override
  Future<void> stopAll() async {}
  @override
  bool isPlaying(AudioChannel channel) => false;
  @override
  Future<void> dispose() async {}
}

/// One recorded [TarfAudioService.play] call.
@immutable
class PlayCall {
  const PlayCall({
    required this.spec,
    required this.channel,
    required this.loop,
    required this.duration,
    required this.playThroughSilent,
  });
  final SoundSpec spec;
  final AudioChannel channel;
  final bool loop;
  final Duration? duration;
  final bool playThroughSilent;
}

/// Records calls for unit/widget tests. `blockPlayback=true` simulates a web
/// autoplay block (play() returns false).
class FakeAudioService implements TarfAudioService {
  FakeAudioService({this.blockPlayback = false});

  bool blockPlayback;
  final List<PlayCall> plays = [];
  final List<AudioChannel> stops = [];
  int stopAllCount = 0;
  final Set<AudioChannel> _active = {};

  @override
  Future<bool> play(SoundSpec spec,
      {required AudioChannel channel,
      bool loop = false,
      Duration? duration,
      bool playThroughSilent = false}) async {
    plays.add(PlayCall(
      spec: spec,
      channel: channel,
      loop: loop,
      duration: duration,
      playThroughSilent: playThroughSilent,
    ));
    if (blockPlayback) return false;
    _active.add(channel);
    return true;
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    stops.add(channel);
    _active.remove(channel);
  }

  @override
  Future<void> stopAll() async {
    stopAllCount++;
    _active.clear();
  }

  @override
  bool isPlaying(AudioChannel channel) => _active.contains(channel);

  @override
  Future<void> dispose() async {}
}
