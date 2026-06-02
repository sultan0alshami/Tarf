import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/account/application/account_controller.dart';
import 'package:tarf/features/account/application/auth_service.dart';

void main() {
  test('controller mirrors the auth service state', () async {
    final auth = FakeAuthService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
    ]);
    addTearDown(container.dispose);

    expect(container.read(accountControllerProvider).isSignedIn, isFalse);
    await container.read(accountControllerProvider.notifier).signInWithGoogle();
    expect(container.read(accountControllerProvider).isSignedIn, isTrue);
    await container.read(accountControllerProvider.notifier).signOut();
    expect(container.read(accountControllerProvider).isSignedIn, isFalse);
  });

  test('sign-in error is captured, not thrown to the UI', () async {
    final auth = FakeAuthService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
    ]);
    addTearDown(container.dispose);
    await container.read(accountControllerProvider.notifier).signInWithEmail('x@y.com', 'nope');
    expect(container.read(accountControllerProvider).lastError, AuthErrorCode.userNotFound);
  });
}
