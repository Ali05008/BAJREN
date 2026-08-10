import 'entities/phone_verification_result.dart';
import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<AuthUser> signInAnonymously();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Starts phone number verification for [e164Phone] (must already be in
  /// E.164 format, e.g. "+966501234567"). Call again with the same number
  /// to resend the code.
  Future<PhoneVerificationResult> startPhoneVerification(String e164Phone);

  /// Completes phone sign-in using the code the user received by SMS.
  Future<AuthUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });
}
