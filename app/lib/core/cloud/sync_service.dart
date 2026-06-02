import 'dart:async';

import 'package:tarf/core/data/tarf_repository.dart';

import 'sync_models.dart';

/// A value with the timestamp it was last written at (for LWW).
class Versioned {
  const Versioned(this.value, this.updatedAtMs);
  final Object? value;
  final int updatedAtMs;
}

/// Mirrors local writes to the cloud, queues them offline, and merges guest
/// data into the cloud on sign-in. Firestore impl + Fake both satisfy it.
abstract interface class SyncService {
  Stream<SyncStatus> get status;
  WriteQueue get queue;

  /// One-time merge of local guest data into the cloud when a user signs in.
  Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local);

  /// Uploads any queued writes (call on reconnect / after a local write).
  Future<void> pushPending();
}

/// Pure LWW merge. Per key the newer [Versioned.updatedAtMs] wins, EXCEPT
/// [StorageKey.progress], whose per-day counters are merged with MAX so neither
/// side loses activity.
Map<StorageKey, Versioned> mergeOnSignIn({
  required Map<StorageKey, Versioned> local,
  required Map<StorageKey, Versioned> cloud,
}) {
  final keys = {...local.keys, ...cloud.keys};
  final out = <StorageKey, Versioned>{};
  for (final k in keys) {
    final l = local[k];
    final c = cloud[k];
    if (l == null) {
      out[k] = c!;
      continue;
    }
    if (c == null) {
      out[k] = l;
      continue;
    }
    if (k == StorageKey.progress) {
      out[k] = Versioned(
        _mergeProgress(l.value, c.value),
        l.updatedAtMs > c.updatedAtMs ? l.updatedAtMs : c.updatedAtMs,
      );
    } else {
      out[k] = l.updatedAtMs >= c.updatedAtMs ? l : c;
    }
  }
  return out;
}

Map<String, Object?> _mergeProgress(Object? a, Object? b) {
  final ma = (a as Map?)?.cast<String, Object?>() ?? const {};
  final mb = (b as Map?)?.cast<String, Object?>() ?? const {};
  final days = {...ma.keys, ...mb.keys};
  final out = <String, Object?>{};
  for (final d in days) {
    final da = (ma[d] as Map?)?.cast<String, Object?>() ?? const {};
    final db = (mb[d] as Map?)?.cast<String, Object?>() ?? const {};
    final fields = {...da.keys, ...db.keys};
    out[d] = {
      for (final f in fields) f: _maxNum(da[f], db[f]),
    };
  }
  return out;
}

Object? _maxNum(Object? a, Object? b) {
  if (a is num && b is num) return a > b ? a : b;
  return a ?? b;
}

/// In-memory fake: a plain map "cloud", deterministic status transitions.
class FakeSyncService implements SyncService {
  final cloudStore = <StorageKey, Object?>{};
  @override
  final WriteQueue queue = WriteQueue();
  final _status = StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> get status => _status.stream;

  @override
  Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local) async {
    _status.add(SyncStatus.syncing);
    final cloud = {
      for (final e in cloudStore.entries) e.key: Versioned(e.value, 0),
    };
    final merged = mergeOnSignIn(local: local, cloud: cloud);
    merged.forEach((k, v) => cloudStore[k] = v.value);
    _status.add(SyncStatus.synced);
  }

  @override
  Future<void> pushPending() async {
    _status.add(SyncStatus.syncing);
    for (final w in queue.drain()) {
      cloudStore[w.key] = w.value;
    }
    _status.add(SyncStatus.synced);
  }
}
