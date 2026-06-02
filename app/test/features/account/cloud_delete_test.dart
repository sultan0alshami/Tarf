import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/data/prefs_repository.dart';
import 'package:tarf/core/data/tarf_repository.dart';
import 'package:tarf/features/account/application/cloud_account.dart';

void main() {
  test('FakeCloudAccount records deletion of data then account', () async {
    final acct = FakeCloudAccount();
    await acct.deleteCloudData('uid1');
    await acct.deleteAccount();
    expect(acct.deletedData, contains('uid1'));
    expect(acct.accountDeleted, isTrue);
  });

  test('purgeEverything clears local repo and, when signed in, the cloud', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    await repo.write(StorageKey.todos, [
      {'id': 't1'},
    ]);
    final acct = FakeCloudAccount();

    await purgeEverything(repo: repo, cloudAccount: acct, uid: 'uid1');

    expect(repo.read(StorageKey.todos), isNull); // local cleared
    expect(acct.deletedData, contains('uid1')); // cloud data cleared
    expect(acct.accountDeleted, isTrue); // auth account removed
  });

  test('purgeEverything with uid==null clears ONLY local (guest)', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    await repo.write(StorageKey.alarms, [
      {'id': 'a1'},
    ]);
    final acct = FakeCloudAccount();

    await purgeEverything(repo: repo, cloudAccount: acct, uid: null);

    expect(repo.read(StorageKey.alarms), isNull);
    expect(acct.deletedData, isEmpty);
    expect(acct.accountDeleted, isFalse);
  });
}
