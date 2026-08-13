import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google Sign-In and hands the resulting credential to
/// FirebaseAuth directly.
///
/// This is intentionally NOT part of [AuthRepository] / [AuthMethod] —
/// it talks to `FirebaseAuth.instance` directly, the same singleton
/// [FirebaseAuthRepository] listens to via `authStateChanges()`. That
/// means once `signIn()` succeeds here, the app's existing
/// `authStateProvider` picks up the new signed-in user automatically,
/// with zero changes needed to the AuthRepository interface or to
/// DemoAuthRepository.
///
/// REQUIRES: the app's SHA-1 (and ideally SHA-256) fingerprint must be
/// registered in Firebase Console → Project Settings → Your apps →
/// Android app → Add fingerprint, followed by re-downloading
/// google-services.json. Without this, signIn() throws a
/// PlatformException such as "ApiException: 10" (DEVELOPER_ERROR).
class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Returns the signed-in [User] on success, or null if the user
  /// cancelled the Google account picker. Throws on any other failure
  /// (network error, misconfiguration, etc).
  Future<User?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }
}
