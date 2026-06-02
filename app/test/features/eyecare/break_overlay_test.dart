import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_haptics.dart';
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

Widget _host(Widget child, {Locale locale = const Locale('ar')}) =>
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('renders the dhikr and starts break audio for the duration', (
    tester,
  ) async {
    final audio = FakeBreakAudio();
    var finished = false;

    await tester.pumpWidget(
      _host(
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 20),
          audio: audio,
          numerals: NumeralSystem.arabicIndic,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump();

    // The sacred text, transliteration, meaning, and source all render.
    expect(find.text('سُبْحَانَ اللّٰهِ'), findsOneWidget);
    expect(find.text('Subhan-Allah'), findsOneWidget);
    expect(find.text('Glory be to Allah.'), findsOneWidget);
    expect(find.text('Sahih al-Bukhari 6406'), findsOneWidget);

    // Audio was started for exactly the break duration.
    expect(audio.startCount, 1);
    expect(audio.lastDuration, const Duration(seconds: 20));

    // After the duration elapses, the overlay shows the "look back" state.
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('Done'.toUpperCase()), findsNothing); // not upper-cased
    expect(finished, isFalse); // requires explicit Done tap
  });

  testWidgets('strict mode hides skip/snooze during the break', (tester) async {
    final audio = FakeBreakAudio();
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 20),
          audio: audio,
          numerals: NumeralSystem.western,
          strict: true,
          onFinished: () {},
          onSkip: () {},
          onSnooze: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Skip'), findsNothing);
    expect(find.text('Snooze'), findsNothing);
  });

  testWidgets('fires an equal breakEnd haptic when the countdown completes', (
    tester,
  ) async {
    final audio = FakeBreakAudio();
    final sink = RecordingHapticSink();

    await tester.pumpWidget(
      _host(
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 1),
          audio: audio,
          numerals: NumeralSystem.western,
          hapticEnabled: true,
          haptics: AudioHaptics(sink),
          onFinished: () {},
        ),
      ),
    );
    await tester.pump();
    expect(sink.events, isEmpty); // not yet
    await tester.pump(const Duration(milliseconds: 1100));
    expect(sink.events, contains(HapticKind.breakEnd));
  });

  testWidgets('no haptic at completion when hapticEnabled is false', (
    tester,
  ) async {
    final sink = RecordingHapticSink();
    await tester.pumpWidget(
      _host(
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 1),
          audio: FakeBreakAudio(),
          numerals: NumeralSystem.western,
          hapticEnabled: false,
          haptics: AudioHaptics(sink),
          onFinished: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(sink.events, isEmpty);
  });
}
