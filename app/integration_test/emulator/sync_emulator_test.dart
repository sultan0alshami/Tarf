// Emulator integration test: FirestoreSyncService / mirror / merge / delete
// against the Firestore emulator (no live project; project id demo-tarf).
//
// Requires the Local Emulator Suite running (Auth 9099, Firestore 8080) and a
// device. The Firestore emulator needs JDK 21+ (firebase-tools 15).
//
//   cd app/firebase
//   firebase emulators:start --project=demo-tarf --only auth,firestore
//   cd app
//   flutter test integration_test/emulator/sync_emulator_test.dart \
//     --dart-define=TARF_CLOUD=true -d chrome
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tarf/core/cloud/firestore_cloud_account.dart';
import 'package:tarf/core/cloud/firestore_cloud_mirror.dart';
import 'package:tarf/core/cloud/firestore_paths.dart';
import 'package:tarf/core/cloud/firestore_sync_service.dart';
import 'package:tarf/core/cloud/sync_service.dart';
import 'package:tarf/core/data/tarf_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseFirestore db;
  late String uid;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo',
        appId: 'demo',
        messagingSenderId: 'demo',
        projectId: 'demo-tarf',
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    db = FirebaseFirestore.instance..useFirestoreEmulator('127.0.0.1', 8080);
    final cred = await FirebaseAuth.instance.signInAnonymously();
    uid = cred.user!.uid;
  });

  testWidgets('mirror push writes an envelope readable at the per-user path', (tester) async {
    final sync = FirestoreSyncService(db, uid);
    final mirror = FirestoreCloudMirror(sync, () => 1000);
    await mirror.onChange(const RepositoryEvent(StorageKey.todos), [
      {'id': 't1'},
    ]);

    final snap = await db.doc(FirestorePaths(uid).docPathFor(StorageKey.todos)).get();
    expect(snap.exists, isTrue);
    expect((snap.data()!['payload'] as List).single['id'], 't1');
    expect(snap.data()!['updatedAt'], 1000);
  });

  testWidgets('mergeGuestIntoCloud preserves progress via per-day MAX', (tester) async {
    final paths = FirestorePaths(uid);
    // Seed cloud progress (older + a cloud-only day).
    await db.doc(paths.docPathFor(StorageKey.progress)).set({
      'payload': {
        '2026-06-01': {'s': 1, 'fm': 75},
        '2026-05-31': {'s': 3},
      },
      'updatedAt': 100,
    });
    final sync = FirestoreSyncService(db, uid);
    await sync.mergeGuestIntoCloud({
      StorageKey.progress: const Versioned({
        '2026-06-01': {'s': 2, 'fm': 50},
      }, 200),
    });
    final merged =
        (await db.doc(paths.docPathFor(StorageKey.progress)).get()).data()!['payload'] as Map;
    expect((merged['2026-06-01'] as Map)['s'], 2); // max(2,1)
    expect((merged['2026-06-01'] as Map)['fm'], 75); // max(50,75)
    expect((merged['2026-05-31'] as Map)['s'], 3); // cloud-only day kept
  });

  testWidgets('FirestoreCloudAccount deletes the whole state subtree', (tester) async {
    final paths = FirestorePaths(uid);
    await db.doc(paths.docPathFor(StorageKey.alarms)).set({'payload': <Object?>[], 'updatedAt': 1});
    final acct = FirestoreCloudAccount(db, FirebaseAuth.instance);
    await acct.deleteCloudData(uid);
    expect((await db.doc(paths.docPathFor(StorageKey.alarms)).get()).exists, isFalse);
  });
}
