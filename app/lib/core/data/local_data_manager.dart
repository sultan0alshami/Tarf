import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Exports and deletes all locally-stored Tarf data. Backs the in-app
/// data-export and account/data-deletion flows required by the app stores.
/// (Cloud deletion of the Firestore subtree is handled by the sync layer once
/// Firebase is connected — see docs/firebase-setup.md and docs/compliance.)
abstract final class LocalDataManager {
  LocalDataManager._();

  static const keys = <String>[
    'tarf.app_settings.v1',
    'tarf.eyecare_config.v1',
    'tarf.focus_config.v1',
    'tarf.progress.v1',
    'tarf.todos.v1',
    'tarf.alarms.v1',
  ];

  /// A pretty-printed JSON snapshot of everything stored on this device.
  static String exportJson(SharedPreferences prefs) {
    final out = <String, Object?>{};
    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        out[k] = jsonDecode(raw);
      } catch (_) {
        out[k] = raw;
      }
    }
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  static Future<void> deleteAll(SharedPreferences prefs) async {
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
