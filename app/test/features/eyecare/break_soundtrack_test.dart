import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/eyecare/audio/just_audio_break_player.dart';
import 'package:tarf/features/eyecare/domain/dhikr.dart';

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

    // The recitation drop-in pipeline: a dhikr carrying its own `audio` (set by
    // the asset-manifest resolver) plays that clip as a breakBed asset spec,
    // overriding the soundtrack bed. This is the end of the chain that lets the
    // owner drop a clip and hear it on the sacred break.
    test('a dhikr.audio clip plays as a breakBed SoundSpec.asset, overriding the bed',
        () async {
      final fake = FakeAudioService();
      // soundtrackId is the calm synth bed; the dhikr's own clip must win.
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      const dhikr = Dhikr(
        id: 'subhanallah',
        arabic: 'سُبْحَانَ اللّٰهِ',
        transliteration: 'Subhan-Allah',
        english: 'Glory be to Allah.',
        reference: 'Sahih Muslim 2694',
        audio: 'assets/audio/recitation/subhanallah.ogg',
      );
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
        dhikr: dhikr,
      );
      expect(fake.plays, hasLength(1));
      final p = fake.plays.single;
      expect(p.channel, AudioChannel.breakBed);
      expect(p.spec.isAsset, isTrue);
      expect(p.spec.assetPath, 'assets/audio/recitation/subhanallah.ogg');
      expect(p.spec.role, SoundRole.breakBed);
      expect(p.duration, const Duration(seconds: 20));
    });

    test('a dhikr with null audio falls back to the soundtrack bed (synth)',
        () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      const dhikr = Dhikr(
        id: 'subhanallah',
        arabic: 'سُبْحَانَ اللّٰهِ',
        transliteration: 'Subhan-Allah',
        english: 'Glory be to Allah.',
        reference: 'Sahih Muslim 2694',
        // No recitation clip dropped for this dhikr.
      );
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
        dhikr: dhikr,
      );
      final p = fake.plays.single;
      expect(p.spec.isAsset, isFalse); // synth calm bed
      expect(p.spec.id, 'calm');
    });
  });
}
