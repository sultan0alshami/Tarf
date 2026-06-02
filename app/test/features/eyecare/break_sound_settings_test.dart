import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/presentation/eyecare_settings_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';

Widget _host(SharedPreferences prefs, FakeAudioService audio) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EyeCareSettingsScreen(),
      ),
    );

void main() {
  testWidgets('break-sound picker changes the soundtrack and previews it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();

    await tester.pumpWidget(_host(prefs, audio));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EyeCareSettingsScreen)),
    );
    expect(container.read(eyeCareConfigProvider).breakSoundtrack, 'calm');

    // The break-sound row lives below the fold; scroll it fully into view, then
    // open it and choose "Chime".
    await tester.scrollUntilVisible(
      find.text('Break sound'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Break sound'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Break sound'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chime').last);
    await tester.pumpAndSettle();

    expect(container.read(eyeCareConfigProvider).breakSoundtrack, 'chime');
    // Choosing previews the sound on the preview channel.
    expect(audio.plays.any((p) => p.channel == AudioChannel.preview), isTrue);
  });
}
