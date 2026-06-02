import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Collapses the foreground (AlarmHost/EyeCareHost) and background (OS
/// notification) firing paths into a single logical fire per alarm-minute.
///
/// Stored as a JSON map { guardKey -> claimedAtMillis } so claims survive a
/// process restart (the OS may deliver a notification while the app is dead,
/// then the user opens the app within the same minute). Entries older than 24h
/// are pruned on every claim.
class DoubleFireGuard {
  DoubleFireGuard(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'tarf.fire_guard.v1';
  static const _ttl = Duration(hours: 24);

  Map<String, int> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, Object?>)
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  /// Atomically claims [guardKey] as of [now]. Returns true if THIS caller is
  /// the first to claim it (and should proceed to ring/show); false if it was
  /// already claimed (caller must do nothing).
  bool claim(String guardKey, DateTime now) {
    final map = _read();
    final cutoff = now.subtract(_ttl).millisecondsSinceEpoch;
    map.removeWhere((_, ms) => ms < cutoff); // prune stale
    final already = map.containsKey(guardKey);
    if (!already) map[guardKey] = now.millisecondsSinceEpoch;
    // Persist (prune + possible insert). Fire-and-forget; read path is sync.
    _prefs.setString(_key, jsonEncode(map));
    return !already;
  }
}
