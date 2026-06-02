import 'dart:math' as math;
import 'dart:typed_data';

import 'sound_spec.dart';

/// Renders [spec] to an in-memory 16-bit PCM mono WAV. Additive layers, each
/// with attack + (decay | sustained) envelope; a soft overall fade prevents
/// clicks at the boundaries; a final hard limit guarantees no int16 clipping.
/// The byte length is a deterministic function of the duration, so tests can
/// assert "sound ends == duration".
Uint8List synthesizeTone(SoundSpec spec, {Duration? duration, int sampleRate = 44100}) {
  final dur = duration ?? spec.defaultDuration;
  final seconds = dur.inMilliseconds / 1000.0;
  final n = (seconds * sampleRate).round().clamp(1, 1 << 30);
  final buf = Float64List(n);

  final overallFade = math.min(0.08, seconds / 4); // gentle in/out
  for (final layer in spec.layers) {
    final startIdx = (layer.startSec * sampleRate).round();
    final w = 2 * math.pi * layer.frequencyHz;
    for (var i = math.max(0, startIdx); i < n; i++) {
      final tLayer = (i - startIdx) / sampleRate;
      double env;
      if (layer.sustain) {
        env = 1.0;
      } else {
        env = math.exp(-tLayer * layer.decay);
      }
      if (tLayer < layer.attack && layer.attack > 0) {
        env *= tLayer / layer.attack;
      }
      final phase = w * tLayer;
      final sample = switch (layer.waveform) {
        Waveform.sine => math.sin(phase),
        Waveform.triangle =>
          2 / math.pi * math.asin(math.sin(phase)),
      };
      buf[i] += layer.peak * env * sample;
    }
  }

  // Overall fade in/out across the whole sound.
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    double f = 1.0;
    if (t < overallFade) {
      f = t / overallFade;
    } else if (t > seconds - overallFade) {
      f = math.max(0.0, (seconds - t) / overallFade);
    }
    buf[i] *= f * spec.gain;
  }

  return _toWav(buf, sampleRate);
}

Uint8List _toWav(Float64List samples, int sampleRate) {
  final n = samples.length;
  const bytesPerSample = 2;
  final dataSize = n * bytesPerSample;
  final bytes = BytesBuilder();
  void writeStr(String s) => bytes.add(s.codeUnits);
  void writeU32(int v) =>
      bytes.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void writeU16(int v) => bytes.add([v & 0xff, (v >> 8) & 0xff]);

  writeStr('RIFF');
  writeU32(36 + dataSize);
  writeStr('WAVE');
  writeStr('fmt ');
  writeU32(16);
  writeU16(1); // PCM
  writeU16(1); // mono
  writeU32(sampleRate);
  writeU32(sampleRate * bytesPerSample);
  writeU16(bytesPerSample);
  writeU16(16);
  writeStr('data');
  writeU32(dataSize);

  final pcm = Uint8List(dataSize);
  final view = ByteData.view(pcm.buffer);
  for (var i = 0; i < n; i++) {
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    view.setInt16(i * 2, s, Endian.little);
  }
  bytes.add(pcm);
  return bytes.toBytes();
}
