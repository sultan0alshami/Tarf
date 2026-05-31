import 'package:flutter/material.dart';

/// Central design tokens for Tarf.
///
/// Calm-through-restraint: near-monochrome surfaces + a single warm accent
/// (teal-green, which reads as both eye-care and Islamic). Whitespace and depth
/// are the primary tools — color is used sparingly for the active/running state
/// and primary actions only.
abstract final class TarfTokens {
  TarfTokens._();

  // ---- Brand seed ----
  /// The one warm accent. A calm, low-chroma teal-green.
  static const Color seed = Color(0xFF0E7C66);

  // ---- Spacing scale (4pt grid) ----
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

  // ---- Minimum tap target (accessibility) ----
  static const double minTapTarget = 44;

  // ---- Break screen backgrounds (warm paper light / near-black dark) ----
  static const Color breakBgLight = Color(0xFFF7F5F0);
  static const Color breakBgDark = Color(0xFF0B0F0E);

  // ---- Font families (bundled OFL fonts; see pubspec assets) ----
  /// SF-Pro-like UI sans with tabular figures.
  static const String fontUi = 'Inter';

  /// Fully-vocalized Arabic font for sacred text. Never substituted.
  static const String fontArabic = 'Amiri';
}
