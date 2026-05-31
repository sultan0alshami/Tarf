import 'package:flutter/material.dart';

/// Central design tokens for Tarf — the "Calm Sanctuary" system (see design.md).
abstract final class TarfTokens {
  TarfTokens._();

  /// Brand seed (ColorScheme.fromSeed source, logo, charts).
  static const Color seed = Color(0xFF0E7C66);

  // ---- Spacing (4pt grid) ----
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 16;
  static const double space4 = 24;
  static const double space5 = 40;
  static const double space6 = 64;

  // ---- Corner radii ----
  static const double radiusS = 8;
  static const double radiusM = 16;
  static const double radiusL = 28;
  static const double radiusXL = 40;

  // ---- Progress ring ----
  static const double ringStroke = 10;
  static const double ringStrokeLarge = 14;

  static const double minTapTarget = 44;

  // ---- Fonts (bundled OFL) ----
  static const String fontUi = 'Inter';
  static const String fontArabic = 'Amiri';
}

/// Custom semantic colors not covered by Material's [ColorScheme], exposed as a
/// [ThemeExtension] so widgets read `Theme.of(context).extension<TarfColors>()!`.
@immutable
class TarfColors extends ThemeExtension<TarfColors> {
  const TarfColors({
    required this.accentContainer,
    required this.elevated,
    required this.overlay,
    required this.textTertiary,
    required this.dhikrGround,
    required this.ringTrack,
    required this.success,
    required this.warning,
    required this.warningText,
    required this.dhikrTranslit,
    required this.dhikrEnglish,
    required this.dhikrSource,
  });

  final Color accentContainer;
  final Color elevated; // surface level 2
  final Color overlay; // surface level 3 (glass tint base)
  final Color textTertiary; // AA-corrected
  final Color dhikrGround; // most reverent surface
  final Color ringTrack;
  final Color success;
  final Color warning; // fills/icons
  final Color warningText; // copy
  final Color dhikrTranslit; // solid, on dhikr ground
  final Color dhikrEnglish;
  final Color dhikrSource;

  static const dark = TarfColors(
    accentContainer: Color(0xFF0E3C32),
    elevated: Color(0xFF1C2322),
    overlay: Color(0xFF232B2A),
    textTertiary: Color(0xFF9AA4A1),
    dhikrGround: Color(0xFF0E1A16),
    ringTrack: Color(0xFF23302C),
    success: Color(0xFF5FCB94),
    warning: Color(0xFFE0A65A),
    warningText: Color(0xFFE0A65A),
    dhikrTranslit: Color(0xFFC8CFCD),
    dhikrEnglish: Color(0xFFA7B2AF),
    dhikrSource: Color(0xFF8B9491),
  );

  static const light = TarfColors(
    accentContainer: Color(0xFFC5EFE5),
    elevated: Color(0xFFF1EEE7),
    overlay: Color(0xFFFBFAF6),
    textTertiary: Color(0xFF6E7672),
    dhikrGround: Color(0xFFF7F5F0),
    ringTrack: Color(0xFFE6E2D9),
    success: Color(0xFF2E7D55),
    warning: Color(0xFFB5752A),
    warningText: Color(0xFF8A5410),
    dhikrTranslit: Color(0xFF2A3330),
    dhikrEnglish: Color(0xFF5A6562),
    dhikrSource: Color(0xFF6E7672),
  );

  @override
  TarfColors copyWith({
    Color? accentContainer,
    Color? elevated,
    Color? overlay,
    Color? textTertiary,
    Color? dhikrGround,
    Color? ringTrack,
    Color? success,
    Color? warning,
    Color? warningText,
    Color? dhikrTranslit,
    Color? dhikrEnglish,
    Color? dhikrSource,
  }) {
    return TarfColors(
      accentContainer: accentContainer ?? this.accentContainer,
      elevated: elevated ?? this.elevated,
      overlay: overlay ?? this.overlay,
      textTertiary: textTertiary ?? this.textTertiary,
      dhikrGround: dhikrGround ?? this.dhikrGround,
      ringTrack: ringTrack ?? this.ringTrack,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      dhikrTranslit: dhikrTranslit ?? this.dhikrTranslit,
      dhikrEnglish: dhikrEnglish ?? this.dhikrEnglish,
      dhikrSource: dhikrSource ?? this.dhikrSource,
    );
  }

  @override
  TarfColors lerp(ThemeExtension<TarfColors>? other, double t) {
    if (other is! TarfColors) return this;
    return TarfColors(
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      dhikrGround: Color.lerp(dhikrGround, other.dhikrGround, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      dhikrTranslit: Color.lerp(dhikrTranslit, other.dhikrTranslit, t)!,
      dhikrEnglish: Color.lerp(dhikrEnglish, other.dhikrEnglish, t)!,
      dhikrSource: Color.lerp(dhikrSource, other.dhikrSource, t)!,
    );
  }
}

/// Convenience accessor.
extension TarfColorsX on BuildContext {
  TarfColors get tarf => Theme.of(this).extension<TarfColors>()!;
}
