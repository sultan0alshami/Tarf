import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';
import 'package:tarf/features/focus/application/focus_controller.dart';
import 'package:tarf/features/focus/domain/focus_models.dart';

void main() {
  testWidgets('plays a focusTransition chime when work completes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tarfAudioServiceProvider.overrideWithValue(audio),
    ]);
    addTearDown(container.dispose);

    // Tiny work duration so one tick completes it.
    await container.read(focusConfigProvider.notifier).update(
          const FocusConfig(work: Duration(seconds: 1)),
        );
    container.read(focusControllerProvider.notifier).startWork();

    // Pump the real 1s ticker.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(audio.plays.where((p) => p.channel == AudioChannel.focus), hasLength(1));
    expect(audio.plays.single.spec.role, SoundRole.focusTransition);

    // Cancel the controller's periodic ticker before teardown.
    container.read(focusControllerProvider.notifier).reset();
  });

  test('no chime when sound is disabled', () {
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      late SharedPreferences prefs;
      // getInstance is async; resolve synchronously within fakeAsync.
      SharedPreferences.getInstance().then((p) => prefs = p);
      async.flushMicrotasks();
      final audio = FakeAudioService();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ]);
      container.read(eyeCareConfigProvider.notifier)
          .update(const EyeCareConfig(soundEnabled: false));
      async.flushMicrotasks();
      container.read(focusConfigProvider.notifier)
          .update(const FocusConfig(work: Duration(seconds: 1)));
      container.read(focusControllerProvider.notifier).startWork();
      async.elapse(const Duration(seconds: 1));
      expect(audio.plays.where((p) => p.channel == AudioChannel.focus), isEmpty);
      container.dispose();
    });
  });
}
