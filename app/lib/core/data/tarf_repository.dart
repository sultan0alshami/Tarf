/// Logical storage keys. `id` is the EXACT SharedPreferences key used today, so
/// the prefs-backed implementation is byte-compatible with existing data and the
/// Firestore mirror can map each key to one document.
enum StorageKey {
  settings('tarf.app_settings.v1'),
  eyecareConfig('tarf.eyecare_config.v1'),
  focusConfig('tarf.focus_config.v1'),
  progress('tarf.progress.v1'),
  todos('tarf.todos.v1'),
  alarms('tarf.alarms.v1'),
  // Reserved for Phase 3 multi-timer list; additive, no call-site churn here.
  timers('tarf.timers.v1');

  const StorageKey(this.id);
  final String id;

  static StorageKey? fromId(String id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

/// Emitted on every write/delete so a [CloudMirror] can fan-out to the cloud.
class RepositoryEvent {
  const RepositoryEvent(this.key, {this.deleted = false});
  final StorageKey key;
  final bool deleted;
}

/// The SINGLE persistence seam for every feature. All settings, eye-rests,
/// focus/progress, todos, alarms (and future timers) go through here so a cloud
/// mirror can be attached without touching call sites again. Values are opaque
/// JSON values (a Map for object blobs, a List for todos/alarms) — field
/// additions from other phases need no repository change.
abstract interface class TarfRepository {
  /// Synchronous read (data is loaded at startup). Null if absent. The decoded
  /// JSON value: a `Map<String, Object?>` for object blobs or a `List` for the
  /// todos/alarms arrays.
  Object? read(StorageKey key);

  /// Persists [value] (any JSON value) and notifies [changes]. The local write
  /// is the source of truth.
  Future<void> write(StorageKey key, Object? value);

  /// Removes [key] and emits a tombstone event.
  Future<void> delete(StorageKey key);

  /// Removes every known key (backs delete-all).
  Future<void> clearAll();

  /// Fires after each local write/delete (drives the optional cloud mirror).
  Stream<RepositoryEvent> get changes;

  /// A pretty-printed JSON snapshot of all keys (backs data export).
  String exportJson();
}
