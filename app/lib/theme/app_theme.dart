import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the light and dark [ThemeData] for Tarf from a single seed.
///
/// Material 3, low-chroma, with tabular figures on the UI font so countdown
/// digits never jitter. Both themes are generated from [TarfTokens.seed] so the
/// accent stays harmonious across light/dark.
abstract final class TarfTheme {
  TarfTheme._();

  static ThemeData light({ColorScheme? dynamicScheme}) =>
      _base(Brightness.light, dynamicScheme);

  static ThemeData dark({ColorScheme? dynamicScheme}) =>
      _base(Brightness.dark, dynamicScheme);

  static ThemeData _base(Brightness brightness, ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: TarfTokens.seed,
          brightness: brightness,
        );

    // Tabular figures so monospaced countdown/timer digits don't shift width.
    const tabularFigures = [FontFeature.tabularFigures()];

    final baseText = (brightness == Brightness.light
            ? Typography.material2021().black
            : Typography.material2021().white)
        .apply(fontFamily: TarfTokens.fontUi);

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(fontFeatures: tabularFigures),
      displayMedium:
          baseText.displayMedium?.copyWith(fontFeatures: tabularFigures),
      headlineLarge:
          baseText.headlineLarge?.copyWith(fontFeatures: tabularFigures),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: textTheme,
      fontFamily: TarfTokens.fontUi,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TarfTokens.radiusM),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(TarfTokens.minTapTarget, TarfTokens.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TarfTokens.radiusM),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        useIndicator: true,
      ),
    );
  }
}
