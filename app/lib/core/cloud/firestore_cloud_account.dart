import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:tarf/core/cloud/firestore_paths.dart';
import 'package:tarf/core/data/tarf_repository.dart';
import 'package:tarf/features/account/application/cloud_account.dart';

/// Deletes a user's Firestore subtree (all state docs + the profile doc) then
/// their auth account. Backs the cloud branch of the mandatory delete-all.
class FirestoreCloudAccount implements CloudAccount {
  FirestoreCloudAccount(this._db, this._auth);
  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  @override
  Future<void> deleteCloudData(String uid) async {
    final paths = FirestorePaths(uid);
    final batch = _db.batch();
    for (final k in StorageKey.values) {
      batch.delete(_db.doc(paths.docPathFor(k)));
    }
    batch.delete(_db.doc(paths.userRoot)); // profile doc if any
    await batch.commit();
  }

  @override
  Future<void> deleteAccount() => _auth.currentUser?.delete() ?? Future.value();
}
