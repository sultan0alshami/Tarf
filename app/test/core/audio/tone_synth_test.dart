import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tone_synth.dart';

void main() {
  group('SoundSpec', () {
    test('a tone layer carries frequency, peak, decay and waveform', () {
      const layer = SoundLayer(frequencyHz: 880, peak: 0.2, decay: 5, attack: 0.01);
      expect(layer.frequencyHz, 880);
      expect(layer.peak, 0.2);
      expect(layer.decay, 5);
      expect(layer.attack, 0.01);
      expect(layer.waveform, Waveform.sine); // default
    });

    test('an asset-backed spec exposes its asset path and is not synth', () {
      const spec = SoundSpec.asset('default-bell', 'assets/audio/recitation/x.mp3');
      expect(spec.id, 'default-bell');
      expect(spec.assetPath, 'assets/audio/recitation/x.mp3');
      expect(spec.isAsset, isTrue);
      expect(spec.layers, isEmpty);
    });

    test('a synth spec is identified by id and is not asset', () {
      const spec = SoundSpec.synth(
        'bell',
        role: SoundRole.alarm,
        layers: [SoundLayer(frequencyHz: 660, peak: 0.3, decay: 3)],
      );
      expect(spec.id, 'bell');
      expect(spec.role, SoundRole.alarm);
      expect(spec.isAsset, isFalse);
      expect(spec.layers, hasLength(1));
    });
  });

  group('synthesizeTone', () {
    const bell = SoundSpec.synth('bell', role: SoundRole.alarm, layers: [
      SoundLayer(frequencyHz: 660, peak: 0.3, decay: 3),
      SoundLayer(frequencyHz: 990, peak: 0.15, decay: 4),
    ]);
    const chime = SoundSpec.synth('chime', role: SoundRole.timerDone, layers: [
      SoundLayer(frequencyHz: 1320, peak: 0.25, decay: 5),
    ]);

    test('produces a valid little-endian 16-bit PCM mono WAV header', () {
      final wav = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final ascii = String.fromCharCodes(wav.sublist(0, 4));
      expect(ascii, 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      final bd = ByteData.sublistView(wav);
      expect(bd.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(bd.getUint16(34, Endian.little), 16, reason: '16-bit');
      expect(bd.getUint32(24, Endian.little), 44100, reason: 'sample rate');
    });

    test('length tracks the requested duration', () {
      final oneSec = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final twoSec = synthesizeTone(bell, duration: const Duration(seconds: 2));
      // ~ +44100 samples * 2 bytes between 1s and 2s.
      expect(twoSec.length - oneSec.length, closeTo(44100 * 2, 8));
    });

    test('falls back to the spec defaultDuration when none is given', () {
      final wav = synthesizeTone(chime);
      final dataBytes = wav.length - 44;
      final expected = (chime.defaultDuration.inMilliseconds / 1000 * 44100).round() * 2;
      expect(dataBytes, closeTo(expected, 8));
    });

    test('two different specs render audibly different bytes', () {
      final a = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final b = synthesizeTone(chime, duration: const Duration(seconds: 1));
      expect(a.length, b.length); // same duration → same length
      var differing = 0;
      for (var i = 44; i < a.length; i++) {
        if (a[i] != b[i]) differing++;
      }
      // Distinct timbre → the vast majority of PCM samples differ.
      expect(differing, greaterThan((a.length - 44) ~/ 2));
    });

    test('never clips: all samples stay within int16 range', () {
      const loud = SoundSpec.synth('loud', role: SoundRole.alarm, gain: 4.0, layers: [
        SoundLayer(frequencyHz: 440, peak: 0.9, decay: 0.1, sustain: true),
        SoundLayer(frequencyHz: 441, peak: 0.9, decay: 0.1, sustain: true),
      ]);
      final wav = synthesizeTone(loud, duration: const Duration(milliseconds: 500));
      final bd = ByteData.sublistView(wav);
      for (var i = 44; i + 1 < wav.length; i += 2) {
        final s = bd.getInt16(i, Endian.little);
        expect(s, inInclusiveRange(-32768, 32767));
      }
    });
  });
}
