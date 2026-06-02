// just_audio marks StreamAudioResponse experimental, but it is the documented,
// widely-used way to serve in-memory audio; safe to use here.
// ignore_for_file: experimental_member_use
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'sound_spec.dart';
import 'tarf_audio_service.dart';
import 'tone_synth.dart';

/// Real cross-platform engine: one [AudioPlayer] per [AudioChannel] so lanes are
/// independent. Synth specs are rendered to an in-memory WAV (data-URI on web,
/// byte source on native); asset specs are loaded from the bundle. Looping uses
/// just_audio's [LoopMode]; an optional [Duration] auto-stops a looped sound.
class JustAudioService implements TarfAudioService {
  final Map<AudioChannel, AudioPlayer> _players = {};
  final Map<AudioChannel, Timer> _autoStop = {};
  AudioSession? _session;
  bool _sessionConfigured = false;

  AudioPlayer _playerFor(AudioChannel channel) =>
      _players.putIfAbsent(channel, AudioPlayer.new);

  Future<void> _configureSession({required bool playThroughSilent}) async {
    if (kIsWeb) return; // no audio_session on web
    _session ??= await AudioSession.instance;
    // Reconfigure if the silent-mode requirement changed.
    await _session!.configure(AudioSessionConfiguration(
      avAudioSessionCategory: playThroughSilent
          ? AVAudioSessionCategory.playback
          : AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.duckOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: playThroughSilent
            ? AndroidAudioUsage.alarm
            : AndroidAudioUsage.assistanceSonification,
      ),
      androidWillPauseWhenDucked: false,
    ));
    _sessionConfigured = true;
    await _session!.setActive(true);
  }

  @override
  Future<bool> play(SoundSpec spec,
      {required AudioChannel channel,
      bool loop = false,
      Duration? duration,
      bool playThroughSilent = false}) async {
    final player = _playerFor(channel);
    _autoStop.remove(channel)?.cancel();
    try {
      await _configureSession(playThroughSilent: playThroughSilent);
      if (spec.isAsset) {
        await player.setAsset(spec.assetPath!);
      } else {
        final wav = synthesizeTone(spec, duration: loop ? null : duration);
        if (kIsWeb) {
          await player.setAudioSource(
            AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
          );
        } else {
          await player.setAudioSource(_BytesSource(wav));
        }
      }
      await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await player.seek(Duration.zero);
      await player.play();
      if (loop && duration != null) {
        _autoStop[channel] = Timer(duration, () => stop(channel));
      }
      return true;
    } catch (_) {
      // Blocked/failed playback (e.g. web autoplay without a gesture) must never
      // break the experience; the caller falls back to the visual cue.
      return false;
    }
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    _autoStop.remove(channel)?.cancel();
    try {
      await _players[channel]?.stop();
    } catch (_) {}
  }

  @override
  Future<void> stopAll() async {
    for (final c in _players.keys.toList()) {
      await stop(c);
    }
  }

  @override
  bool isPlaying(AudioChannel channel) =>
      _players[channel]?.playing ?? false;

  @override
  Future<void> dispose() async {
    for (final t in _autoStop.values) {
      t.cancel();
    }
    _autoStop.clear();
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    if (!kIsWeb && _sessionConfigured) {
      try {
        await _session?.setActive(false);
      } catch (_) {}
    }
  }
}

/// Serves synthesized WAV bytes to just_audio on native platforms.
class _BytesSource extends StreamAudioSource {
  _BytesSource(this._bytes);
  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}
