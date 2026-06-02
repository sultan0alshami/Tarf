import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/cloud/sync_models.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  test('enqueue keeps only the latest write per key (coalesces)', () {
    final q = WriteQueue();
    q.enqueue(PendingWrite(StorageKey.progress, {'2026-06-01': 1}, atMs: 1));
    q.enqueue(PendingWrite(StorageKey.progress, {'2026-06-01': 2}, atMs: 2));
    q.enqueue(PendingWrite(StorageKey.todos, [
      {'id': 't1'},
    ], atMs: 3));
    expect(q.length, 2);
    expect(q.peek(StorageKey.progress)!.value, {'2026-06-01': 2});
  });

  test('drain returns pending writes oldest-first and empties the queue', () {
    final q = WriteQueue()
      ..enqueue(PendingWrite(StorageKey.todos, <Object?>[], atMs: 1))
      ..enqueue(PendingWrite(StorageKey.alarms, <Object?>[], atMs: 2));
    final drained = q.drain();
    expect(drained.map((w) => w.key), [StorageKey.todos, StorageKey.alarms]);
    expect(q.length, 0);
  });

  test('serializes/deserializes for durable persistence', () {
    final q = WriteQueue()..enqueue(PendingWrite(StorageKey.settings, {'a': 1}, atMs: 5));
    final restored = WriteQueue.fromJson(q.toJson());
    expect(restored.peek(StorageKey.settings)!.value, {'a': 1});
  });
}
