import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarf/core/data/tarf_repository.dart';
import 'firestore_paths.dart';
import 'sync_models.dart';
import 'sync_service.dart';

/// Firestore-backed SyncService for a single signed-in uid. Reads/writes LWW
/// envelopes; reuses the pure [mergeOnSignIn]. Firestore's built-in offline
/// persistence is the durable cache; our [WriteQueue] is the explicit retry
/// buffer for writes that have not yet reached the SDK.
class FirestoreSyncService implements SyncService {
  FirestoreSyncService(this._db, String uid) : _paths = FirestorePaths(uid);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  @override
  final WriteQueue queue = WriteQueue();
  final _status = StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> get status => _status.stream;

  DocumentReference<Map<String, dynamic>> _ref(StorageKey k) =>
      _db.doc(_paths.docPathFor(k));

  @override
  Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local) async {
    _status.add(SyncStatus.syncing);
    try {
      final cloud = <StorageKey, Versioned>{};
      for (final k in StorageKey.values) {
        final snap = await _ref(k).get();
        final data = snap.data();
        if (data != null) {
          final env = SyncEnvelope.fromMap(data.cast<String, Object?>());
          cloud[k] = Versioned(env.payload, env.updatedAtMs);
        }
      }
      final merged = mergeOnSignIn(local: local, cloud: cloud);
      final batch = _db.batch();
      merged.forEach((k, v) =>
          batch.set(_ref(k), SyncEnvelope.wrap(v.value, updatedAtMs: v.updatedAtMs).toMap()));
      await batch.commit();
      _status.add(SyncStatus.synced);
    } catch (_) {
      _status.add(SyncStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> pushPending() async {
    _status.add(SyncStatus.syncing);
    try {
      for (final w in queue.drain()) {
        await _ref(w.key).set(SyncEnvelope.wrap(w.value, updatedAtMs: w.atMs).toMap());
      }
      _status.add(SyncStatus.synced);
    } catch (_) {
      _status.add(SyncStatus.error);
      rethrow;
    }
  }
}
