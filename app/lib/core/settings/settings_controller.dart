import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../format/numerals.dart';
import 'app_settings.dart';

/// Provides the [SharedPreferences] instance. Overridden in `main()` after async
/// initialization so the rest of the app can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

const _settingsKey = 'tarf.app_settings.v1';

/// Holds [AppSettings], loading from and persisting to [SharedPreferences].
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_settingsKey, jsonEncode(next.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) => _persist(state.copyWith(themeMode: mode));

  Future<void> setLocale(String localeCode) =>
      _persist(state.copyWith(localeCode: localeCode));

  Future<void> setNumeralSystem(NumeralSystem? system) => _persist(
        system == null
            ? state.copyWith(clearNumeralSystem: true)
            : state.copyWith(numeralSystem: system),
      );

  Future<void> setReduceMotion({required bool value}) =>
      _persist(state.copyWith(reduceMotion: value));

  Future<void> completeOnboarding() =>
      _persist(state.copyWith(onboardingComplete: true));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
