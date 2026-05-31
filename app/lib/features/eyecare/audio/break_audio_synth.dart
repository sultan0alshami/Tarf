import 'dart:math' as math;
import 'dart:typed_data';

/// Synthesizes the break sound as an in-memory 16-bit PCM mono WAV: a soft start
/// chime, a gentle two-tone pad that fades in/out for the full [duration], and a
/// distinct end chime that lands exactly at the end. No bundled/licensed audio
/// file is needed, and the sound ending is the cue that the break is over.
Uint8List synthesizeBreakWav(Duration duration, {int sampleRate = 44100}) {
  final seconds = duration.inMilliseconds / 1000.0;
  final n = (seconds * sampleRate).round().clamp(1, 1 << 30);
  final buf = Float64List(n);

  // Gentle pad (two low sines) with a 1.2s fade in and out.
  const fade = 1.2;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    double env;
    if (t < fade) {
      env = t / fade;
    } else if (t > seconds - fade) {
      env = math.max(0.0, (seconds - t) / fade);
    } else {
      env = 1.0;
    }
    final tone =
        (math.sin(2 * math.pi * 196.0 * t) + math.sin(2 * math.pi * 261.63 * t)) /
            2;
    buf[i] = 0.05 * env * tone;
  }

  _addChime(buf, sampleRate, atSec: 0.05, freq: 880.0, peak: 0.18);
  _addChime(buf, sampleRate, atSec: seconds - 0.6, freq: 1318.5, peak: 0.22);

  return _toWav(buf, sampleRate);
}

void _addChime(
  Float64List buf,
  int sampleRate, {
  required double atSec,
  required double freq,
  required double peak,
  double durSec = 0.8,
}) {
  final start = (atSec * sampleRate).round();
  final len = (durSec * sampleRate).round();
  for (var k = 0; k < len; k++) {
    final i = start + k;
    if (i < 0 || i >= buf.length) continue;
    final t = k / sampleRate;
    final decay = math.exp(-t * 5); // gentle exponential decay
    buf[i] += peak * decay * math.sin(2 * math.pi * freq * t);
  }
}

Uint8List _toWav(Float64List samples, int sampleRate) {
  final n = samples.length;
  const bytesPerSample = 2; // 16-bit
  final dataSize = n * bytesPerSample;
  final bytes = BytesBuilder();

  void writeStr(String s) => bytes.add(s.codeUnits);
  void writeU32(int v) => bytes.add([
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ]);
  void writeU16(int v) => bytes.add([v & 0xff, (v >> 8) & 0xff]);

  writeStr('RIFF');
  writeU32(36 + dataSize);
  writeStr('WAVE');
  writeStr('fmt ');
  writeU32(16); // PCM chunk size
  writeU16(1); // PCM
  writeU16(1); // mono
  writeU32(sampleRate);
  writeU32(sampleRate * bytesPerSample); // byte rate
  writeU16(bytesPerSample); // block align
  writeU16(16); // bits per sample
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
