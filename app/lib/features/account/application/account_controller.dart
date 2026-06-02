import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

/// Overridden in main() with FirebaseAuthService when cloud is enabled,
/// otherwise a FakeAuthService (sign-in stays disabled in the UI regardless).
final authServiceProvider = Provider<AuthService>((ref) => FakeAuthService());

/// UI-facing account state.
class AccountState {
  const AccountState({this.user, this.busy = false, this.lastError});
  final AuthUser? user;
  final bool busy;
  final AuthErrorCode? lastError;
  bool get isSignedIn => user != null;

  AccountState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? busy,
    AuthErrorCode? lastError,
    bool clearError = false,
  }) =>
      AccountState(
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

class AccountController extends Notifier<AccountState> {
  StreamSubscription<AuthState>? _sub;

  @override
  AccountState build() {
    final auth = ref.watch(authServiceProvider);
    _sub = auth.authState
        .listen((s) => state = state.copyWith(user: s.user, clearUser: !s.isSignedIn));
    ref.onDispose(() => _sub?.cancel());
    return AccountState(user: auth.currentUser);
  }

  AuthService get _auth => ref.read(authServiceProvider);

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await action();
      // Reflect the result immediately; the authState stream keeps the user in
      // sync for out-of-band changes (e.g. token expiry on another device).
      final u = _auth.currentUser;
      state = state.copyWith(user: u, clearUser: u == null);
    } on AuthException catch (e) {
      state = state.copyWith(lastError: e.code);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);
  Future<void> signInWithApple() => _run(_auth.signInWithApple);
  Future<void> signInWithEmail(String email, String password) =>
      _run(() => _auth.signInWithEmail(email, password));
  Future<void> registerWithEmail(String email, String password) =>
      _run(() => _auth.registerWithEmail(email, password));
  Future<void> signOut() => _run(_auth.signOut);
}

final accountControllerProvider =
    NotifierProvider<AccountController, AccountState>(AccountController.new);
