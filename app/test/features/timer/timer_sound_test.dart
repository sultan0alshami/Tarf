import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';
import 'package:tarf/features/timer/domain/saved_timer.dart';
import 'package:tarf/features/timer/presentation/timer_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, FakeAudioService audio) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TimerScreen(),
      ),
    );

void main() {
  testWidgets('plays a looped completion sound on the timer channel at zero',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();

    await tester.pumpWidget(_host(prefs, audio));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerScreen)),
    );
    final c = container.read(timerControllerProvider.notifier)
      ..setDuration(const Duration(seconds: 1))
      ..start();
    await tester.pump(const Duration(seconds: 1)); // ticker -> zero
    await tester.pump(); // listener runs

    expect(audio.plays, hasLength(1));
    expect(audio.plays.single.channel, AudioChannel.timer);
    expect(audio.plays.single.loop, isTrue);
    expect(audio.plays.single.spec.role, SoundRole.timerDone);
    expect(find.text("Time's up"), findsOneWidget); // calm time's-up state
    // The flag was acknowledged so a rebuild does not double-trigger.
    expect(container.read(timerControllerProvider).justFinished, isFalse);

    // Reset stops the completion sound.
    c.reset();
    await tester.pump();
    expect(audio.stops, contains(AudioChannel.timer));
  });

  testWidgets('a saved timer plays ITS chosen sound (not the role default)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();

    await tester.pumpWidget(_host(prefs, audio));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerScreen)),
    );
    // Load a saved timer whose sound is 'bell', then run it to zero.
    container.read(timerControllerProvider.notifier)
      ..runSaved(const SavedTimer(
        id: 'b1',
        label: 'Bell',
        duration: Duration(seconds: 1),
        soundId: 'bell',
      ))
      ..start();
    await tester.pump(const Duration(seconds: 1)); // ticker -> zero
    await tester.pump(); // listener runs

    expect(audio.plays, hasLength(1));
    // The picked sound 'bell' is played, retagged to the timerDone role.
    expect(audio.plays.single.spec.id, 'bell');
    expect(audio.plays.single.spec.role, SoundRole.timerDone);
    expect(audio.plays.single.channel, AudioChannel.timer);
    expect(audio.plays.single.loop, isTrue);
  });
}
