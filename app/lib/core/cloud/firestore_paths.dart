import 'package:tarf/core/data/tarf_repository.dart';

/// Per-user document layout. Every StorageKey blob lives at
/// `users/{uid}/state/{key}` so adding fields inside a blob (P1 sounds, P3
/// prayer/timer) needs no path change. (See Task 6 for optional fine-grained
/// dailyProgress.)
class FirestorePaths {
  FirestorePaths(this.uid);
  final String uid;

  String get userRoot => 'users/$uid';
  String docPathFor(StorageKey key) => 'users/$uid/state/${key.name}';
}

/// Wraps a JSON blob with its last-write timestamp for LWW conflict resolution.
class SyncEnvelope {
  const SyncEnvelope(this.payload, this.updatedAtMs);
  final Object? payload;
  final int updatedAtMs;

  SyncEnvelope.wrap(Object? payload, {required int updatedAtMs})
      : this(payload, updatedAtMs);

  Map<String, Object?> toMap() => {'payload': payload, 'updatedAt': updatedAtMs};

  factory SyncEnvelope.fromMap(Map<String, Object?> m) =>
      SyncEnvelope(m['payload'], (m['updatedAt'] as num?)?.toInt() ?? 0);
}
