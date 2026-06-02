import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/cloud_mirror.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  test('NoopCloudMirror ignores events and never throws', () async {
    const mirror = NoopCloudMirror();
    await mirror.onChange(const RepositoryEvent(StorageKey.settings), null);
    // no-op: nothing to assert beyond "did not throw".
    expect(mirror.isActive, isFalse);
  });

  test('attachMirror forwards repository writes to the mirror', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    final spy = _SpyMirror();
    final detach = attachMirror(repo, spy);
    await repo.write(StorageKey.todos, [
      {'id': 't1'},
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(spy.seen.single.key, StorageKey.todos);
    await detach();
  });
}

class _SpyMirror implements CloudMirror {
  final seen = <RepositoryEvent>[];
  @override
  bool get isActive => true;
  @override
  Future<void> onChange(RepositoryEvent e, Object? value) async => seen.add(e);
}
