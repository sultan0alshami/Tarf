import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/account/application/auth_service.dart';

void main() {
  test('starts signed-out and emits the guest state', () async {
    final auth = FakeAuthService();
    expect(auth.currentUser, isNull);
    expect(await auth.authState.first, const AuthState.signedOut());
  });

  test('Google sign-in produces a user and emits signedIn', () async {
    final auth = FakeAuthService();
    final states = <AuthState>[];
    final sub = auth.authState.listen(states.add);
    final user = await auth.signInWithGoogle();
    expect(user.uid, isNotEmpty);
    expect(auth.currentUser, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isA<AuthState>().having((s) => s.user?.uid, 'uid', user.uid));
    await sub.cancel();
  });

  test('email sign-in rejects a wrong password with AuthException', () async {
    final auth = FakeAuthService()..seedEmailUser('a@b.com', 'right');
    expect(
      () => auth.signInWithEmail('a@b.com', 'wrong'),
      throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.wrongPassword)),
    );
  });

  test('signOut returns to guest', () async {
    final auth = FakeAuthService();
    await auth.signInWithGoogle();
    await auth.signOut();
    expect(auth.currentUser, isNull);
  });

  test('deleteAccount clears the current user', () async {
    final auth = FakeAuthService();
    await auth.signInWithGoogle();
    await auth.deleteAccount();
    expect(auth.currentUser, isNull);
  });
}
