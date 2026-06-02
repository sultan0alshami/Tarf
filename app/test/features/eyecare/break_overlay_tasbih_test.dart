import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/format/numerals.dart';
import 'package:tarf/core/settings/settings_controller.dart';
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

Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('tasbih is opt-in and never wraps the sacred line',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(
      prefs,
      BreakOverlay(
        dhikr: _dhikr,
        duration: const Duration(seconds: 20),
        audio: FakeBreakAudio(),
        numerals: NumeralSystem.western,
        showTasbih: true, // opt-in flag exposed for tests/integration
        onFinished: () {},
      ),
    ));
    await tester.pump();

    // Sacred line still present exactly once.
    expect(find.text('سُبْحَانَ اللّٰهِ'), findsOneWidget);

    // The tap target exists and increments the visible count.
    expect(find.text(Numerals.formatInt(0, NumeralSystem.western)),
        findsWidgets);
    await tester.tap(find.byKey(const ValueKey('tasbihTapTarget')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget); // count incremented

    // The tap target is at least 44px (a11y).
    final size = tester.getSize(find.byKey(const ValueKey('tasbihTapTarget')));
    expect(size.width >= 44 && size.height >= 44, isTrue);
  });

  testWidgets('tasbih hidden by default (showTasbih false)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_host(
      prefs,
      BreakOverlay(
        dhikr: _dhikr,
        duration: const Duration(seconds: 20),
        audio: FakeBreakAudio(),
        numerals: NumeralSystem.western,
        onFinished: () {},
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('tasbihTapTarget')), findsNothing);
  });
}
