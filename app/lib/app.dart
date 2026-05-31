import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/settings/settings_controller.dart';
import 'features/alarm/presentation/alarm_host.dart';
import 'features/eyecare/application/eyecare_engine.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires theme, Arabic-first localization (true RTL), and routing.
class TarfApp extends ConsumerWidget {
  const TarfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(goRouterProvider);

    // Screenshot/debug affordance: force a theme regardless of the system or
    // saved setting (no effect on normal builds, where FORCE_THEME is empty).
    const forceTheme = String.fromEnvironment('FORCE_THEME');
    final themeMode = switch (forceTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => settings.themeMode,
    };

    return MaterialApp.router(
      title: 'Tarf',
      debugShowCheckedModeBanner: false,
      theme: TarfTheme.light(),
      darkTheme: TarfTheme.dark(),
      themeMode: themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => AlarmHost(
        child: EyeCareHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
