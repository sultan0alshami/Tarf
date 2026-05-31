// just_audio marks StreamAudioResponse experimental, but it is the documented,
// widely-used way to serve in-memory audio; safe to use here.
// ignore_for_file: experimental_member_use
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/dhikr.dart';
import 'break_audio.dart';
import 'break_audio_synth.dart';

/// Real cross-platform break audio. Plays a synthesized 20-second WAV via
/// just_audio: a data URI on web, an in-memory byte source on native. Honors
/// the silent setting and degrades gracefully (the visual ring still drives the
/// break) if playback is blocked (e.g. web autoplay without a user gesture).
class JustAudioBreakPlayer implements BreakAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> start({
    required Duration duration,
    required bool soundEnabled,
    Dhikr? dhikr,
  }) async {
    if (!soundEnabled) return;
    final wav = synthesizeBreakWav(duration);
    try {
      if (kIsWeb) {
        await _player.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
        );
      } else {
        await _player.setAudioSource(_BytesSource(wav));
      }
      await _player.play();
    } catch (_) {
      // Best-effort: a blocked/failed play must never break the experience.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Serves the synthesized WAV bytes to just_audio on native platforms.
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
