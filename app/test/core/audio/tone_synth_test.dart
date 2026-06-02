import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';

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
}
