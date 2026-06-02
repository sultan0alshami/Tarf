// Emulator integration test: real firebase_auth against the Auth emulator.
//
// Requires the Local Emulator Suite running (Auth on 127.0.0.1:9099) and a
// device. The Firestore/Auth emulators need JDK 21+ (firebase-tools 15).
//
//   cd app/firebase
//   firebase emulators:start --project=demo-tarf --only auth,firestore
//   cd app
//   flutter test integration_test/emulator/auth_emulator_test.dart \
//     --dart-define=TARF_CLOUD=true -d chrome
//
// Google/Apple need real OAuth and are NOT emulator-testable (covered by the
// FakeAuthService unit tests + manual owner verification). Email/Password is.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tarf/features/account/application/auth_service.dart';
import 'package:tarf/features/account/application/firebase_auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
  });

  testWidgets('register + sign-in + delete against the Auth emulator', (tester) async {
    final auth = FirebaseAuthService(FirebaseAuth.instance);
    final email = 'u${DateTime.now().microsecondsSinceEpoch}@example.com';

    final created = await auth.registerWithEmail(email, 'pw-123456');
    expect(created.uid, isNotEmpty);

    await auth.signOut();
    expect(auth.currentUser, isNull);

    final back = await auth.signInWithEmail(email, 'pw-123456');
    expect(back.uid, created.uid);

    await auth.deleteAccount();
    expect(auth.currentUser, isNull);
  });

  testWidgets('wrong password surfaces AuthErrorCode.wrongPassword', (tester) async {
    final auth = FirebaseAuthService(FirebaseAuth.instance);
    final email = 'u${DateTime.now().microsecondsSinceEpoch}@example.com';
    await auth.registerWithEmail(email, 'right-123456');
    await auth.signOut();
    await expectLater(
      () => auth.signInWithEmail(email, 'wrong-123456'),
      throwsA(isA<AuthException>().having(
        (e) => e.code,
        'code',
        anyOf(AuthErrorCode.wrongPassword, AuthErrorCode.userNotFound),
      )),
    );
  });
}
