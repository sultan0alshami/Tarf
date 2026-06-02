import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

void main() {
  group('EyeCareConfig.breakSoundtrack', () {
    test('defaults to calm', () {
      expect(const EyeCareConfig().breakSoundtrack, 'calm');
    });

    test('round-trips through JSON', () {
      const cfg = EyeCareConfig(breakSoundtrack: 'chime');
      final restored = EyeCareConfig.fromJson(cfg.toJson());
      expect(restored.breakSoundtrack, 'chime');
    });

    test('fromJson without the key falls back to calm (back-compat)', () {
      final restored = EyeCareConfig.fromJson(const {'enabled': true});
      expect(restored.breakSoundtrack, 'calm');
    });

    test('copyWith updates only the soundtrack', () {
      const cfg = EyeCareConfig();
      final next = cfg.copyWith(breakSoundtrack: 'chime');
      expect(next.breakSoundtrack, 'chime');
      expect(next.soundEnabled, cfg.soundEnabled);
    });
  });
}
