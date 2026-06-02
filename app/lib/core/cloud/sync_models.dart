import 'dart:convert';

import 'package:tarf/core/data/tarf_repository.dart';

enum SyncStatus { offline, syncing, synced, error }

/// One queued local write awaiting upload.
class PendingWrite {
  PendingWrite(this.key, this.value, {required this.atMs});
  final StorageKey key;
  final Object? value;
  final int atMs;

  Map<String, Object?> toJson() => {'k': key.id, 'v': value, 't': atMs};
  static PendingWrite fromJson(Map<String, Object?> j) => PendingWrite(
        StorageKey.fromId(j['k']! as String)!,
        j['v'],
        atMs: (j['t']! as num).toInt(),
      );
}

/// An offline write queue that coalesces by key (latest wins) and is durable.
class WriteQueue {
  final _items = <StorageKey, PendingWrite>{};

  int get length => _items.length;

  void enqueue(PendingWrite w) {
    final existing = _items[w.key];
    if (existing == null || w.atMs >= existing.atMs) _items[w.key] = w;
  }

  PendingWrite? peek(StorageKey key) => _items[key];

  /// Oldest-first, then clears.
  List<PendingWrite> drain() {
    final list = _items.values.toList()..sort((a, b) => a.atMs.compareTo(b.atMs));
    _items.clear();
    return list;
  }

  String toJson() => jsonEncode(_items.values.map((w) => w.toJson()).toList());

  static WriteQueue fromJson(String raw) {
    final q = WriteQueue();
    for (final e in (jsonDecode(raw) as List).cast<Map<String, Object?>>()) {
      q.enqueue(PendingWrite.fromJson(e));
    }
    return q;
  }
}
