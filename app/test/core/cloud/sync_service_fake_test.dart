import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/cloud/sync_models.dart';
import 'package:tarf/core/cloud/sync_service.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  group('mergeOnSignIn (last-write-wins per key; progress unions)', () {
    test('newer cloud blob wins over older local blob', () {
      final result = mergeOnSignIn(
        local: {StorageKey.settings: const Versioned({'localeCode': 'en'}, 100)},
        cloud: {StorageKey.settings: const Versioned({'localeCode': 'ar'}, 200)},
      );
      expect((result[StorageKey.settings]!.value! as Map)['localeCode'], 'ar');
    });

    test('newer local blob wins over older cloud blob', () {
      final result = mergeOnSignIn(
        local: {StorageKey.settings: const Versioned({'localeCode': 'en'}, 300)},
        cloud: {StorageKey.settings: const Versioned({'localeCode': 'ar'}, 200)},
      );
      expect((result[StorageKey.settings]!.value! as Map)['localeCode'], 'en');
    });

    test('progress merges per-day taking the MAX counters (no loss either way)', () {
      final result = mergeOnSignIn(
        local: {
          StorageKey.progress: const Versioned({
            '2026-06-01': {'s': 2, 'fm': 50},
          }, 100),
        },
        cloud: {
          StorageKey.progress: const Versioned({
            '2026-06-01': {'s': 1, 'fm': 75},
            '2026-05-31': {'s': 3, 'fm': 60},
          }, 200),
        },
      );
      final p = result[StorageKey.progress]!.value! as Map;
      expect((p['2026-06-01'] as Map)['s'], 2); // max(2,1)
      expect((p['2026-06-01'] as Map)['fm'], 75); // max(50,75)
      expect((p['2026-05-31'] as Map)['s'], 3); // cloud-only day kept
    });

    test('progress merge carries the day string and handles a missing counter', () {
      final result = mergeOnSignIn(
        local: {
          StorageKey.progress: const Versioned({
            '2026-06-01': {'day': '2026-06-01', 'fm': 40}, // no 's'
          }, 100),
        },
        cloud: {
          StorageKey.progress: const Versioned({
            '2026-06-01': {'day': '2026-06-01', 's': 3, 'fm': 10},
          }, 200),
        },
      );
      final day = (result[StorageKey.progress]!.value! as Map)['2026-06-01'] as Map;
      expect(day['day'], '2026-06-01'); // string carried, never max-merged
      expect(day['fm'], 40); // max(40,10)
      expect(day['s'], 3); // present on only one side
    });

    test('progress merge asserts (no silent local-wins) on a non-numeric counter', () {
      // A non-num where a counter is expected is a schema bug; it must surface
      // loudly in dev rather than masquerade as a max (the old _maxNum footgun).
      expect(
        () => mergeOnSignIn(
          local: {
            StorageKey.progress: const Versioned({
              '2026-06-01': {'fm': 'oops'},
            }, 100),
          },
          cloud: {
            StorageKey.progress: const Versioned({
              '2026-06-01': {'fm': 5},
            }, 200),
          },
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('progress merge asserts on an unexpected (non-counter) field', () {
      // Both sides present so the merge path (not the LWW shortcut) runs.
      expect(
        () => mergeOnSignIn(
          local: {
            StorageKey.progress: const Versioned({
              '2026-06-01': {'fm': 1, 'newField': 9},
            }, 100),
          },
          cloud: {
            StorageKey.progress: const Versioned({
              '2026-06-01': {'fm': 2},
            }, 200),
          },
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('key present on only one side is kept', () {
      final result = mergeOnSignIn(
        local: {
          StorageKey.todos: const Versioned([
            {'id': 't1'},
          ], 100),
        },
        cloud: const {},
      );
      expect(result[StorageKey.todos]!.value, [
        {'id': 't1'},
      ]);
    });
  });

  group('FakeSyncService', () {
    test('pushPending writes the queue into the fake cloud store', () async {
      final sync = FakeSyncService();
      sync.queue.enqueue(PendingWrite(StorageKey.todos, [
        {'id': 't1'},
      ], atMs: 1));
      await sync.pushPending();
      expect(sync.cloudStore[StorageKey.todos], [
        {'id': 't1'},
      ]);
      expect(sync.queue.length, 0);
    });

    test('status transitions offline -> syncing -> synced', () async {
      final sync = FakeSyncService();
      final seen = <SyncStatus>[];
      final sub = sync.status.listen(seen.add);
      await sync.pushPending();
      await Future<void>.delayed(Duration.zero);
      expect(seen, containsAllInOrder([SyncStatus.syncing, SyncStatus.synced]));
      await sub.cancel();
    });
  });
}
