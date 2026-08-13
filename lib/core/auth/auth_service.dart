import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Central authentication service for BAJREN.
/// Supports three sign-in paths that can all coexist:
///  1. Email + Password (classic, supports username-or-email lookup upstream)
///  2. Email Link ("magic link", passwordless)
///  3. Google Sign-In
///
/// NOTE: Google Sign-In requires the app's SHA-1 (and ideally SHA-256)
/// fingerprint to be registered in the Firebase Console under
/// Project Settings > Your apps > Android app, with a fresh
/// google-services.json downloaded afterwards. Without this step,
/// signInWithGoogle() will throw a PlatformException (usually
/// ApiException: 10 / DEVELOPER_ERROR).
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------
  // Email + Password
  // ---------------------------------------------------------------------

  /// Registers a brand-new account with email + password.
  /// Throws [FirebaseAuthException] on failure (e.g. email-already-in-use,
  /// weak-password).
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in with either an email address OR a username.
  /// If [identifier] doesn't look like an email, [resolveEmailForUsername]
  /// must be supplied by the caller (looked up from Firestore/RTDB) to
  /// translate the username into the account's real email before calling
  /// Firebase Auth, since Firebase Auth itself only understands emails.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------------------------------------------------------------------
  // Email Link (magic link / passwordless)
  // ---------------------------------------------------------------------

  static const String _emailLinkContinueUrl =
      'https://bajren-25964.web.app/finishSignIn';

  Future<void> sendSignInLinkToEmail(String email) {
    final actionCodeSettings = ActionCodeSettings(
      url: _emailLinkContinueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.bajren.bajren',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
    return _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: actionCodeSettings,
    );
  }

  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
  }

  // ---------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the Google sign-in flow.
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // ---------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
