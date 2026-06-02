import 'package:tarf/core/data/tarf_repository.dart';

/// Deletes a user's CLOUD footprint: their Firestore subtree, then their auth
/// account. Local clearing is the repository's job (see [purgeEverything]).
abstract interface class CloudAccount {
  /// Recursively deletes /users/{uid}. Safe to call before deleteAccount.
  Future<void> deleteCloudData(String uid);

  /// Deletes the currently signed-in auth account.
  Future<void> deleteAccount();
}

/// In-memory fake for unit tests.
class FakeCloudAccount implements CloudAccount {
  final deletedData = <String>[];
  bool accountDeleted = false;

  @override
  Future<void> deleteCloudData(String uid) async => deletedData.add(uid);

  @override
  Future<void> deleteAccount() async => accountDeleted = true;
}

/// The single mandatory "delete everything" routine wired to the Account screen.
/// Always clears local. When [uid] is non-null (signed in), it ALSO deletes the
/// cloud data and the auth account — in that order, so a failure mid-way still
/// leaves the account able to retry. Guest ([uid] == null) clears local only.
Future<void> purgeEverything({
  required TarfRepository repo,
  required CloudAccount cloudAccount,
  required String? uid,
}) async {
  if (uid != null) {
    await cloudAccount.deleteCloudData(uid);
    await cloudAccount.deleteAccount();
  }
  await repo.clearAll();
}
