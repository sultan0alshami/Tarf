import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  late PrefsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = PrefsRepository(await SharedPreferences.getInstance());
  });

  test('write then read round-trips a JSON map', () async {
    await repo.write(StorageKey.settings, {'localeCode': 'ar', 'reduceMotion': true});
    expect(repo.read(StorageKey.settings), {'localeCode': 'ar', 'reduceMotion': true});
  });

  test('write then read round-trips a JSON array (todos/alarms)', () async {
    await repo.write(StorageKey.todos, [
      {'id': 't1'},
    ]);
    expect(repo.read(StorageKey.todos), [
      {'id': 't1'},
    ]);
  });

  test('missing key reads as null', () {
    expect(repo.read(StorageKey.todos), isNull);
  });

  test('writes emit a RepositoryEvent for the cloud mirror', () async {
    final events = <RepositoryEvent>[];
    final sub = repo.changes.listen(events.add);
    await repo.write(StorageKey.progress, {'2026-06-01': 1});
    await Future<void>.delayed(Duration.zero);
    expect(events.single.key, StorageKey.progress);
    await sub.cancel();
  });

  test('delete removes the value and emits a tombstone event', () async {
    await repo.write(StorageKey.alarms, [
      {'x': 1},
    ]);
    final events = <RepositoryEvent>[];
    final sub = repo.changes.listen(events.add);
    await repo.delete(StorageKey.alarms);
    await Future<void>.delayed(Duration.zero);
    expect(repo.read(StorageKey.alarms), isNull);
    expect(events.single.deleted, isTrue);
    await sub.cancel();
  });

  test('clearAll wipes every known key', () async {
    await repo.write(StorageKey.settings, {'a': 1});
    await repo.write(StorageKey.todos, [
      {'b': 2},
    ]);
    await repo.clearAll();
    for (final k in StorageKey.values) {
      expect(repo.read(k), isNull, reason: k.name);
    }
  });
}
