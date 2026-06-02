import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/eyecare/audio/just_audio_break_player.dart';

void main() {
  group('JustAudioBreakPlayer (over TarfAudioService)', () {
    test('plays the configured soundtrack on the breakBed channel for the duration', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'chime');
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
      );
      expect(fake.plays, hasLength(1));
      final p = fake.plays.single;
      expect(p.channel, AudioChannel.breakBed);
      expect(p.spec.id, 'chime');
      expect(p.duration, const Duration(seconds: 20));
    });

    test('does nothing when sound is disabled', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: false,
      );
      expect(fake.plays, isEmpty);
    });

    test('stop() stops the breakBed channel', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      await player.start(duration: const Duration(seconds: 5), soundEnabled: true);
      await player.stop();
      expect(fake.stops, contains(AudioChannel.breakBed));
    });

    test('defaults to NOT playing through silent', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
      );
      expect(fake.plays.single.playThroughSilent, isFalse);
    });

    test('forwards loudThroughSilence as playThroughSilent when opted in',
        () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(
        audio: fake,
        soundtrackId: 'calm',
        loudThroughSilence: true,
      );
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
      );
      expect(fake.plays.single.playThroughSilent, isTrue);
    });

    test('a recitation asset id takes the bundled-asset code path (isAsset)', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(
        audio: fake,
        soundtrackId: 'recitation',
        recitationAssetPath: 'assets/audio/recitation/001.mp3',
      );
      await player.start(duration: const Duration(seconds: 20), soundEnabled: true);
      final p = fake.plays.single;
      expect(p.spec.isAsset, isTrue);
      expect(p.spec.assetPath, 'assets/audio/recitation/001.mp3');
      expect(p.spec.role, SoundRole.breakBed);
    });
  });
}
