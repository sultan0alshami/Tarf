import 'package:flutter/material.dart';

import '../format/numerals.dart';

/// User-facing app-wide preferences that must work fully offline (guest mode)
/// and are mirrored to the cloud once signed in.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'ar',
    this.numeralSystem,
    this.reduceMotion = false,
    this.onboardingComplete = false,
  });

  final ThemeMode themeMode;

  /// 'ar' (default, Arabic-first) or 'en'.
  final String localeCode;

  /// Null = follow the locale default (Arabic-Indic for ar, Western for en).
  final NumeralSystem? numeralSystem;

  final bool reduceMotion;

  /// Whether the first-launch onboarding has been completed.
  final bool onboardingComplete;

  Locale get locale => Locale(localeCode);

  NumeralSystem get effectiveNumerals =>
      numeralSystem ?? Numerals.defaultForLocale(localeCode);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    NumeralSystem? numeralSystem,
    bool clearNumeralSystem = false,
    bool? reduceMotion,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      numeralSystem:
          clearNumeralSystem ? null : (numeralSystem ?? this.numeralSystem),
      reduceMotion: reduceMotion ?? this.reduceMotion,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'localeCode': localeCode,
        'numeralSystem': numeralSystem?.name,
        'reduceMotion': reduceMotion,
        'onboardingComplete': onboardingComplete,
      };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      themeMode: ThemeMode.values.byName(
        (json['themeMode'] as String?) ?? ThemeMode.system.name,
      ),
      localeCode: (json['localeCode'] as String?) ?? 'ar',
      numeralSystem: switch (json['numeralSystem'] as String?) {
        final String name when name.isNotEmpty =>
          NumeralSystem.values.byName(name),
        _ => null,
      },
      reduceMotion: (json['reduceMotion'] as bool?) ?? false,
      onboardingComplete: (json['onboardingComplete'] as bool?) ?? false,
    );
  }
}
