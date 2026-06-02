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

/// The numeric per-day counter fields of [DailyProgress] (its `toJson` keys
/// minus the `day` string). These are the ONLY fields max-merged so neither side
/// loses activity. Keeping this explicit means a future non-numeric progress
/// field can't masquerade as a max-merge (which previously degraded to a silent
/// local-wins): it would trip the assert in [_mergeDay] in debug builds.
const _progressCounterFields = {'fm', 's', 'bt', 'bs'};

Map<String, Object?> _mergeProgress(Object? a, Object? b) {
  final ma = (a as Map?)?.cast<String, Object?>() ?? const {};
  final mb = (b as Map?)?.cast<String, Object?>() ?? const {};
  final days = {...ma.keys, ...mb.keys};
  final out = <String, Object?>{};
  for (final d in days) {
    final da = (ma[d] as Map?)?.cast<String, Object?>() ?? const {};
    final db = (mb[d] as Map?)?.cast<String, Object?>() ?? const {};
    out[d] = _mergeDay(da, db);
  }
  return out;
}

/// Merges one day's record. The `day` string is carried through (both sides key
/// the same day); the known numeric counters are max-merged; any unexpected
/// field is asserted against (so a schema change without updating this merge
/// fails loudly in dev) and otherwise preserved non-destructively.
Map<String, Object?> _mergeDay(
  Map<String, Object?> da,
  Map<String, Object?> db,
) {
  final out = <String, Object?>{};
  // Preserve the day key verbatim (string, not a counter).
  final day = da['day'] ?? db['day'];
  if (day != null) out['day'] = day;

  for (final f in _progressCounterFields) {
    final av = da[f];
    final bv = db[f];
    if (av == null && bv == null) continue;
    out[f] = _maxNum(av, bv);
  }

  // Anything outside the known schema: surface loudly in dev, keep safely in
  // release rather than dropping the user's data.
  final unexpected = {...da.keys, ...db.keys}
    ..removeAll(_progressCounterFields)
    ..remove('day');
  assert(
    unexpected.isEmpty,
    'DailyProgress gained unexpected field(s) $unexpected — add them to '
    '_progressCounterFields (numeric) or handle their merge explicitly.',
  );
  for (final f in unexpected) {
    out[f] = da[f] ?? db[f];
  }
  return out;
}

/// Max of two values that are expected to be numeric counters. A type mismatch
/// (a non-numeric value where a counter is expected) is a schema bug: assert in
/// debug, then degrade safely by treating a non-num as 0 so a stray value can
/// never silently win over a real count.
num _maxNum(Object? a, Object? b) {
  assert(
    (a == null || a is num) && (b == null || b is num),
    'Progress counter expected num, got a=${a.runtimeType}, b=${b.runtimeType}',
  );
  final na = a is num ? a : 0;
  final nb = b is num ? b : 0;
  return na > nb ? na : nb;
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
