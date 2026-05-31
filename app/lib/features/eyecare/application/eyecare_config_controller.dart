import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/eyecare_config.dart';

const _key = 'tarf.eyecare_config.v1';

/// Holds the persisted [EyeCareConfig].
class EyeCareConfigController extends Notifier<EyeCareConfig> {
  @override
  EyeCareConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return const EyeCareConfig();
    try {
      return EyeCareConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const EyeCareConfig();
    }
  }

  Future<void> update(EyeCareConfig config) async {
    state = config;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }
}

final eyeCareConfigProvider =
    NotifierProvider<EyeCareConfigController, EyeCareConfig>(
  EyeCareConfigController.new,
);
