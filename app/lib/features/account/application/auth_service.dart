import 'dart:async';

/// A signed-in identity (provider-agnostic).
class AuthUser {
  const AuthUser({required this.uid, this.email, this.displayName, this.isAnonymous = false});
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
}

/// Stream-friendly auth status.
class AuthState {
  const AuthState.signedOut() : user = null;
  const AuthState.signedIn(AuthUser this.user);
  final AuthUser? user;
  bool get isSignedIn => user != null;

  @override
  bool operator ==(Object other) =>
      other is AuthState && other.user?.uid == user?.uid;
  @override
  int get hashCode => user?.uid.hashCode ?? 0;
}

enum AuthErrorCode {
  cancelled,
  network,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  accountExistsWithDifferentCredential,
  requiresRecentLogin,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.code, [this.message]);
  final AuthErrorCode code;
  final String? message;
  @override
  String toString() => 'AuthException($code, $message)';
}

/// Provider-agnostic auth surface. Firebase impl and Fake impl both satisfy it.
abstract interface class AuthService {
  AuthUser? get currentUser;
  Stream<AuthState> get authState;

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> registerWithEmail(String email, String password);

  Future<void> signOut();

  /// Deletes the AUTH account (may throw requiresRecentLogin). Firestore data
  /// deletion is handled separately by CloudAccount.
  Future<void> deleteAccount();
}

/// In-memory fake for unit tests. No Firebase.
class FakeAuthService implements AuthService {
  AuthUser? _user;
  final _controller = StreamController<AuthState>.broadcast();
  final _emailUsers = <String, String>{}; // email -> password
  int _seq = 0;

  void seedEmailUser(String email, String password) => _emailUsers[email] = password;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthState> get authState async* {
    yield _user == null ? const AuthState.signedOut() : AuthState.signedIn(_user!);
    yield* _controller.stream;
  }

  AuthUser _emit(AuthUser u) {
    _user = u;
    _controller.add(AuthState.signedIn(u));
    return u;
  }

  @override
  Future<AuthUser> signInWithGoogle() async =>
      _emit(AuthUser(uid: 'g${_seq++}', email: 'google@example.com', displayName: 'Google User'));

  @override
  Future<AuthUser> signInWithApple() async =>
      _emit(AuthUser(uid: 'a${_seq++}', email: 'apple@example.com'));

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final stored = _emailUsers[email];
    if (stored == null) throw const AuthException(AuthErrorCode.userNotFound);
    if (stored != password) throw const AuthException(AuthErrorCode.wrongPassword);
    return _emit(AuthUser(uid: 'e${_seq++}', email: email));
  }

  @override
  Future<AuthUser> registerWithEmail(String email, String password) async {
    if (_emailUsers.containsKey(email)) {
      throw const AuthException(AuthErrorCode.emailAlreadyInUse);
    }
    _emailUsers[email] = password;
    return _emit(AuthUser(uid: 'e${_seq++}', email: email));
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(const AuthState.signedOut());
  }

  @override
  Future<void> deleteAccount() async {
    _user = null;
    _controller.add(const AuthState.signedOut());
  }
}
