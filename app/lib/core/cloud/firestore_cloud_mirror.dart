import 'package:tarf/core/cloud/sync_models.dart';
import 'package:tarf/core/cloud/sync_service.dart';
import 'package:tarf/core/data/cloud_mirror.dart';
import 'package:tarf/core/data/tarf_repository.dart';

/// Bridges repository writes to the SyncService queue. Active only when signed
/// in. Each local write is enqueued (coalescing by key) then flushed; the
/// SyncService handles status + retries.
class FirestoreCloudMirror implements CloudMirror {
  FirestoreCloudMirror(this._sync, this._nowMs);
  final SyncService _sync;
  final int Function() _nowMs;

  @override
  bool get isActive => true;

  @override
  Future<void> onChange(RepositoryEvent event, Object? value) async {
    _sync.queue.enqueue(PendingWrite(event.key, value, atMs: _nowMs()));
    await _sync.pushPending();
  }
}
