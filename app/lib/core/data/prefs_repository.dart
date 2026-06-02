import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tarf_repository.dart';

/// Local-first default. Identical on-disk format to the pre-Phase-4 controllers:
/// each [StorageKey] is one SharedPreferences string holding the JSON value
/// (object for configs/progress/settings, array for todos/alarms).
class PrefsRepository implements TarfRepository {
  PrefsRepository(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<RepositoryEvent>.broadcast();

  @override
  Stream<RepositoryEvent> get changes => _changes.stream;

  @override
  Object? read(StorageKey key) {
    final raw = _prefs.getString(key.id);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StorageKey key, Object? value) async {
    await _prefs.setString(key.id, jsonEncode(value));
    _changes.add(RepositoryEvent(key));
  }

  @override
  Future<void> delete(StorageKey key) async {
    await _prefs.remove(key.id);
    _changes.add(RepositoryEvent(key, deleted: true));
  }

  @override
  Future<void> clearAll() async {
    for (final k in StorageKey.values) {
      await _prefs.remove(k.id);
      _changes.add(RepositoryEvent(k, deleted: true));
    }
  }

  @override
  String exportJson() {
    final out = <String, Object?>{};
    for (final k in StorageKey.values) {
      final raw = _prefs.getString(k.id);
      if (raw == null) continue;
      try {
        out[k.id] = jsonDecode(raw);
      } catch (_) {
        out[k.id] = raw;
      }
    }
    return const JsonEncoder.withIndent('  ').convert(out);
  }
}
