import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/audio/web_audio_prime.dart';
import 'package:tarf/core/format/numerals.dart';
import 'package:tarf/features/eyecare/audio/break_audio.dart';
import 'package:tarf/features/eyecare/domain/dhikr.dart';
import 'package:tarf/features/eyecare/presentation/break_overlay.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

const _dhikr = Dhikr(
  id: 'subhanallah',
  arabic: 'سُبْحَانَ اللّٰهِ',
  transliteration: 'Subhan-Allah',
  english: 'Glory be to Allah.',
  reference: 'Sahih al-Bukhari 6406',
);

void main() {
  // Reverence guarantee: the web "tap to enable sound" banner must NEVER paint
  // over the sacred dhikr break. The banner lives in MaterialApp.router's
  // builder, which is layered ABOVE the Router's Navigator — so a fullscreen
  // route pushed on the root navigator does NOT cover it by z-order alone. The
  // break therefore suppresses the banner by state; this test locks that in.
  testWidgets('TapToEnableSoundBanner does not render over a pushed BreakOverlay', (
    tester,
  ) async {
    final audio = FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        isWebProvider.overrideWithValue(true),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(container.dispose);
    // Force the banner into its visible state (web + a real autoplay block).
    container.read(webAudioPrimeProvider.notifier).reportBlocked();
    expect(container.read(webAudioPrimeProvider).needsPrime, isTrue);

    final rootNavKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootNavKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HOME'))),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          // Mirror app.dart: the banner sits in the persistent chrome, above the
          // Router's Navigator. If it were not suppressed, it would paint over a
          // pushed fullscreen break — the very thing we forbid.
          builder: (context, child) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Align(
                alignment: Alignment.topCenter,
                child: TapToEnableSoundBanner(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sanity: with no break shown, the banner IS visible over the app chrome.
    expect(find.text('Tap to enable sound'), findsOneWidget);

    // Push the reverent break on the ROOT navigator (mirrors show_break.dart).
    // reduceMotion stops the infinite breathing loop so the frame count is
    // bounded; the banner-suppression we assert is independent of motion.
    unawaited(
      rootNavKey.currentState!.push(
        PageRouteBuilder<void>(
          fullscreenDialog: true,
          pageBuilder: (_, _, _) => BreakOverlay(
            dhikr: _dhikr,
            duration: const Duration(seconds: 20),
            audio: FakeBreakAudio(),
            numerals: NumeralSystem.western,
            reduceMotion: true,
            onFinished: () {},
          ),
        ),
      ),
    );
    // One frame to build the route + run initState, one more for the
    // post-frame enter() that flips the suppression flag, plus the transition.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The sacred line is on screen, and the banner is gone — never above it.
    expect(find.text('سُبْحَانَ اللّٰهِ'), findsOneWidget);
    expect(find.text('Tap to enable sound'), findsNothing);

    // And when the break is dismissed, the banner returns to the chrome.
    // Pump through the exit transition (dispose), then a couple of frames for
    // the deferred leave() microtask and the banner's rebuild.
    rootNavKey.currentState!.pop();
    await tester.pump(); // start the pop
    await tester.pump(const Duration(milliseconds: 500)); // finish transition
    await tester.pump(); // drain leave() microtask
    await tester.pump(); // rebuild banner
    expect(find.text('Tap to enable sound'), findsOneWidget);
  });
}
