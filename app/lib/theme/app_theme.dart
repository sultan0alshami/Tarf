import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the light and dark [ThemeData] for Tarf from the "Calm Sanctuary"
/// palette (see design.md). Dark is canonical; both ship.
abstract final class TarfTheme {
  TarfTheme._();

  static ThemeData light() => _build(Brightness.light, TarfColors.light);
  static ThemeData dark() => _build(Brightness.dark, TarfColors.dark);

  static ThemeData _build(Brightness brightness, TarfColors ext) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: TarfTokens.seed,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFF2FB89B) : const Color(0xFF0B6A57),
      onPrimary: isDark ? const Color(0xFF04201A) : const Color(0xFFFFFFFF),
      primaryContainer: ext.accentContainer,
      onPrimaryContainer: isDark ? const Color(0xFFCFF3E9) : const Color(0xFF04201A),
      tertiary: ext.success,
      surface: isDark ? const Color(0xFF0B0F0E) : const Color(0xFFF7F5F0),
      surfaceContainerLowest: isDark ? const Color(0xFF0B0F0E) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF14191A) : const Color(0xFFFFFFFF),
      surfaceContainer: isDark ? const Color(0xFF14191A) : const Color(0xFFF6F3EC),
      surfaceContainerHigh: ext.elevated,
      surfaceContainerHighest: ext.overlay,
      onSurface: isDark ? const Color(0xFFF4F6F5) : const Color(0xFF15201D),
      onSurfaceVariant: isDark ? const Color(0xFFA7B2AF) : const Color(0xFF5A6562),
      outline: isDark ? const Color(0xFF323B39) : const Color(0xFFE2DFD7),
      outlineVariant: isDark ? const Color(0xFF283230) : const Color(0xFFEBE7DE),
      error: isDark ? const Color(0xFFF08379) : const Color(0xFFC0473B),
    );

    const tabular = [FontFeature.tabularFigures()];
    final base = (isDark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(fontFamily: TarfTokens.fontUi);
    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFeatures: tabular),
      displayMedium: base.displayMedium?.copyWith(fontFeatures: tabular),
      displaySmall: base.displaySmall?.copyWith(fontFeatures: tabular),
      headlineLarge: base.headlineLarge?.copyWith(fontFeatures: tabular),
      headlineMedium: base.headlineMedium?.copyWith(fontFeatures: tabular),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: TarfTokens.fontUi,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: [ext],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TarfTokens.radiusM),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, TarfTokens.minTapTarget),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, TarfTokens.minTapTarget),
          side: BorderSide(color: scheme.outline),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, TarfTokens.minTapTarget),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        useIndicator: true,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 6,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TarfTokens.radiusL)),
        ),
      ),
    );
  }
}
