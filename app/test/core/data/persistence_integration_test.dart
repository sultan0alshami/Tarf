import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/cloud_mirror.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/repository_providers.dart';
import 'package:tarf/core/data/tarf_repository.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/todos/application/todos_controller.dart';

void main() {
  test('todos write goes through the repository and reaches the mirror', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);
    final seen = <StorageKey>[];
    attachMirror(repo, _Spy(seen));

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tarfRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(todosControllerProvider.notifier).add('read Quran', nowMs: 1);
    await Future<void>.delayed(Duration.zero);

    // Persisted via repository (visible to a fresh read) AND mirrored.
    expect(repo.read(StorageKey.todos), isNotNull);
    expect(seen, contains(StorageKey.todos));
  });
}

class _Spy implements CloudMirror {
  _Spy(this.seen);
  final List<StorageKey> seen;
  @override
  bool get isActive => true;
  @override
  Future<void> onChange(RepositoryEvent e, Object? v) async => seen.add(e.key);
}
