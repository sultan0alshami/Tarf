import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository_providers.dart';
import '../data/tarf_repository.dart';
import '../format/numerals.dart';
import 'app_settings.dart';

/// Provides the [SharedPreferences] instance. Overridden in `main()` after async
/// initialization so the rest of the app can read it synchronously. The default
/// [tarfRepositoryProvider] is built from this, so every feature persists
/// through the repository while the on-disk format stays byte-identical.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Holds [AppSettings], loading from and persisting via the [TarfRepository].
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.settings);
    if (raw is! Map) return const AppSettings();
    try {
      return AppSettings.fromJson(raw.cast<String, Object?>());
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref.read(tarfRepositoryProvider).write(StorageKey.settings, next.toJson());
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

  /// Records that the one-time notification priming sheet has been shown, so the
  /// Alarm tab prompts exactly once regardless of the user's choice.
  Future<void> markNotifPrimingShown() =>
      _persist(state.copyWith(notifPrimingShown: true));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
