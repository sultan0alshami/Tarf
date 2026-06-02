import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

/// Firebase-backed AuthService. Constructed only when cloud is enabled (see
/// [FirebaseFlags]); guest builds never instantiate it. Pure error mapping is
/// covered by unit tests; the email/password flow is exercised against the Auth
/// emulator (Google/Apple need real OAuth — verified manually by the owner).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final fb.FirebaseAuth _auth;

  bool _googleReady = false;

  AuthUser? _map(fb.User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email,
          displayName: u.displayName,
          isAnonymous: u.isAnonymous,
        );

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthState> get authState => _auth.authStateChanges().map(
        (u) => u == null ? const AuthState.signedOut() : AuthState.signedIn(_map(u)!),
      );

  AuthUser _require(fb.UserCredential c) => _map(c.user)!;

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      // google_sign_in 7.x requires initialize() exactly once before use.
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize();
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final cred = fb.GoogleAuthProvider.credential(idToken: idToken);
      return _require(await _auth.signInWithCredential(cred));
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthErrorCode.cancelled
            : AuthErrorCode.unknown,
        e.description,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      final a = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final cred = fb.OAuthProvider('apple.com').credential(
        idToken: a.identityToken,
        accessToken: a.authorizationCode,
      );
      return _require(await _auth.signInWithCredential(cred));
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(
        e.code == AuthorizationErrorCode.canceled
            ? AuthErrorCode.cancelled
            : AuthErrorCode.unknown,
        e.message,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      return _require(await _auth.signInWithEmailAndPassword(email: email, password: password));
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AuthUser> registerWithEmail(String email, String password) async {
    try {
      return _require(await _auth.createUserWithEmailAndPassword(email: email, password: password));
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  AuthException _translate(fb.FirebaseAuthException e) => AuthException(
        switch (e.code) {
          'wrong-password' || 'invalid-credential' => AuthErrorCode.wrongPassword,
          'user-not-found' => AuthErrorCode.userNotFound,
          'email-already-in-use' => AuthErrorCode.emailAlreadyInUse,
          'account-exists-with-different-credential' =>
            AuthErrorCode.accountExistsWithDifferentCredential,
          'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
          'network-request-failed' => AuthErrorCode.network,
          _ => AuthErrorCode.unknown,
        },
        e.message,
      );
}
