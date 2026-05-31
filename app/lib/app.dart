import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/settings/settings_controller.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires theme, Arabic-first localization (true RTL), and routing.
class TarfApp extends ConsumerWidget {
  const TarfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Tarf',
      debugShowCheckedModeBanner: false,
      theme: TarfTheme.light(),
      darkTheme: TarfTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
