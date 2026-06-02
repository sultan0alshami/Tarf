import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/audio/web_audio_prime.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

void main() {
  group('WebAudioPrime', () {
    test('on native it reports primed immediately (no banner needed)', () {
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(false),
      ]);
      addTearDown(container.dispose);
      expect(container.read(webAudioPrimeProvider).needsPrime, isFalse);
    });

    test('on web it starts not-yet-primed and can be marked blocked', () {
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(true),
      ]);
      addTearDown(container.dispose);
      expect(container.read(webAudioPrimeProvider).primed, isFalse);
      container.read(webAudioPrimeProvider.notifier).reportBlocked();
      expect(container.read(webAudioPrimeProvider).needsPrime, isTrue);
    });

    test('priming plays a prime tone and clears needsPrime', () async {
      final audio = FakeAudioService();
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(true),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ]);
      addTearDown(container.dispose);
      container.read(webAudioPrimeProvider.notifier).reportBlocked();
      await container.read(webAudioPrimeProvider.notifier).prime();
      expect(audio.plays.single.channel, AudioChannel.preview);
      expect(container.read(webAudioPrimeProvider).primed, isTrue);
      expect(container.read(webAudioPrimeProvider).needsPrime, isFalse);
    });
  });

  testWidgets('TapToEnableSoundBanner shows only when needsPrime and primes on tap',
      (tester) async {
    final audio = FakeAudioService();
    final container = ProviderContainer(overrides: [
      isWebProvider.overrideWithValue(true),
      tarfAudioServiceProvider.overrideWithValue(audio),
    ]);
    addTearDown(container.dispose);
    container.read(webAudioPrimeProvider.notifier).reportBlocked();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: TapToEnableSoundBanner()),
      ),
    ));
    await tester.pump();

    expect(find.text('Tap to enable sound'), findsOneWidget);
    await tester.tap(find.text('Tap to enable sound'));
    await tester.pump();
    expect(audio.plays, isNotEmpty);
    await tester.pump();
    expect(find.text('Tap to enable sound'), findsNothing); // hides once primed
  });
}
