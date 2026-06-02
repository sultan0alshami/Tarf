import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/cloud/firestore_paths.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  test('each StorageKey maps to a stable per-user path', () {
    final p = FirestorePaths('uidX');
    expect(p.docPathFor(StorageKey.settings), 'users/uidX/state/settings');
    expect(p.docPathFor(StorageKey.eyecareConfig), 'users/uidX/state/eyecareConfig');
    expect(p.docPathFor(StorageKey.progress), 'users/uidX/state/progress');
    expect(p.docPathFor(StorageKey.todos), 'users/uidX/state/todos');
    expect(p.docPathFor(StorageKey.alarms), 'users/uidX/state/alarms');
    expect(p.userRoot, 'users/uidX');
  });

  test('encodes a JSON blob into an envelope with payload + updatedAt', () {
    final env = SyncEnvelope.wrap([
      {'id': 't1'},
    ], updatedAtMs: 1000);
    expect(env.toMap()['payload'], [
      {'id': 't1'},
    ]);
    expect(env.toMap()['updatedAt'], 1000);
    final back = SyncEnvelope.fromMap(env.toMap());
    expect(back.payload, [
      {'id': 't1'},
    ]);
    expect(back.updatedAtMs, 1000);
  });
}
