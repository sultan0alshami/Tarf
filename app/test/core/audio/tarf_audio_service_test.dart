import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_catalog.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';

void main() {
  group('FakeAudioService', () {
    test('records play calls with spec, channel, loop and duration', () async {
      final fake = FakeAudioService();
      await fake.play(
        SoundCatalog.byId('bell'),
        channel: AudioChannel.alarm,
        loop: true,
        duration: const Duration(seconds: 60),
        playThroughSilent: true,
      );
      expect(fake.plays, hasLength(1));
      final p = fake.plays.single;
      expect(p.spec.id, 'bell');
      expect(p.channel, AudioChannel.alarm);
      expect(p.loop, isTrue);
      expect(p.duration, const Duration(seconds: 60));
      expect(p.playThroughSilent, isTrue);
    });

    test('stop targets a channel and is recorded', () async {
      final fake = FakeAudioService();
      await fake.play(SoundCatalog.forRole(SoundRole.timerDone),
          channel: AudioChannel.timer, loop: true);
      await fake.stop(AudioChannel.timer);
      expect(fake.stops, [AudioChannel.timer]);
      expect(fake.isPlaying(AudioChannel.timer), isFalse);
    });

    test('isPlaying reflects the latest play/stop per channel', () async {
      final fake = FakeAudioService();
      expect(fake.isPlaying(AudioChannel.focus), isFalse);
      await fake.play(SoundCatalog.forRole(SoundRole.focusTransition),
          channel: AudioChannel.focus);
      expect(fake.isPlaying(AudioChannel.focus), isTrue);
    });
  });

  group('SilentAudioService', () {
    test('never throws and never reports playing', () async {
      const svc = SilentAudioService();
      await svc.play(SoundCatalog.byId('default'), channel: AudioChannel.alarm);
      await svc.stop(AudioChannel.alarm);
      await svc.stopAll();
      await svc.dispose();
      expect(svc.isPlaying(AudioChannel.alarm), isFalse);
    });
  });
}
