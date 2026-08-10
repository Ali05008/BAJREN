import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/entities/phone_verification_result.dart';

/// The project's default Firebase Hosting domain. Firebase Authentication
/// uses this automatically (since the Aug 25, 2025 Dynamic Links shutdown)
/// to generate email sign-in links for mobile apps — no custom domain or
/// Firebase Hosting deploy is required. Must match the Android App Links
/// intent-filter host in AndroidManifest.xml.
const _kEmailLinkHost = 'bajren-25964.firebaseapp.com';

/// Path Firebase uses for email action links. Do not change.
const _kEmailLinkContinueUrl = 'https://$_kEmailLinkHost/finishSignIn';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthUser _map(User user) => AuthUser(
        uid: user.uid,
        displayName: user.displayName ?? user.email,
        isAnonymous: user.isAnonymous,
      );

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map((u) => u == null ? null : _map(u));
  }

  @override
  AuthUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _map(u);
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw StateError('Anonymous sign-in failed');
    }
    return _map(user);
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) throw StateError('Email sign-in failed');
    return _map(user);
  }

  @override
  Future<AuthUser> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) throw StateError('Registration failed');
    return _map(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  @override
  Future<PhoneVerificationResult> startPhoneVerification(
    String e164Phone,
  ) async {
    final completer = Completer<PhoneVerificationResult>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          final user = cred.user;
          if (!completer.isCompleted && user != null) {
            completer.complete(
              PhoneVerificationResult(autoVerifiedUser: _map(user)),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationResult(verificationId: verificationId),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationResult(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  @override
  Future<AuthUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user == null) throw StateError('Phone sign-in failed');
    return _map(user);
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    final settings = ActionCodeSettings(
      url: _kEmailLinkContinueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.bajren.bajren',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
    await _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: settings,
    );
  }

  @override
  bool isEmailSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  @override
  Future<AuthUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final cred = await _auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
    final user = cred.user;
    if (user == null) throw StateError('Email link sign-in failed');
    return _map(user);
  }
}
