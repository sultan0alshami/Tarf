import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_haptics.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/alarm/presentation/alarm_sound.dart';

void main() {
  group('alarm sound controller', () {
    test('startAlarmSound loops the chosen catalog sound for ringDurationSeconds', () async {
      final fake = FakeAudioService();
      final sink = RecordingHapticSink();
      final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
      await ctl.start(
        const AlarmItem(id: 'a', hour: 6, minute: 30, sound: 'bell', ringDurationSeconds: 45),
        hapticEnabled: true,
        playThroughSilent: true,
      );
      final p = fake.plays.single;
      expect(p.channel, AudioChannel.alarm);
      expect(p.spec.id, 'bell');
      expect(p.loop, isTrue);
      expect(p.duration, const Duration(seconds: 45));
      expect(p.playThroughSilent, isTrue);
      expect(sink.events, contains(HapticKind.alarm));
      ctl.dispose();
    });

    test('an unknown sound id falls back to the default spec', () async {
      final fake = FakeAudioService();
      final ctl = AlarmSoundController(audio: fake, haptics: const AudioHaptics());
      await ctl.start(
        const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'does-not-exist'),
        hapticEnabled: false,
      );
      expect(fake.plays.single.spec.id, 'default');
      expect(fake.plays.single.spec.role, SoundRole.alarm);
      ctl.dispose();
    });

    test('stop() stops the alarm channel and the repeating haptic', () async {
      final fake = FakeAudioService();
      final sink = RecordingHapticSink();
      final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
      await ctl.start(
        const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'calm'),
        hapticEnabled: true,
      );
      await ctl.stop();
      expect(fake.stops, contains(AudioChannel.alarm));
      expect(ctl.isRinging, isFalse);
    });

    test('a repeating haptic fires more than once over time', () {
      fakeAsync((async) {
        final fake = FakeAudioService();
        final sink = RecordingHapticSink();
        final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
        ctl.start(
          const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'bell'),
          hapticEnabled: true,
        );
        async.elapse(const Duration(seconds: 5));
        expect(sink.events.where((e) => e == HapticKind.alarm).length,
            greaterThan(1));
        ctl.stop();
      });
    });
  });
}
