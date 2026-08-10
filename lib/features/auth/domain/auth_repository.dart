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
  ///
  /// NOTE: kept for future re-activation of Phone OTP (requires the
  /// Firebase Blaze plan). Not called from the current login flow while
  /// [kActiveAuthMethod] is [AuthMethod.emailLink].
  Future<PhoneVerificationResult> startPhoneVerification(String e164Phone);

  /// Completes phone sign-in using the code the user received by SMS.
  Future<AuthUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  /// Sends a passwordless "magic link" sign-in email to [email]. The link
  /// opens the app (via Android App Links) and completing it signs the
  /// user in — no SMS, no Blaze plan required.
  Future<void> sendEmailSignInLink(String email);

  /// Returns true if [link] is a Firebase email sign-in link (as opposed
  /// to some other deep link the app might receive).
  bool isEmailSignInLink(String link);

  /// Completes sign-in using the link the user opened from their email.
  /// [email] must be the same address the link was sent to.
  Future<AuthUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  });
}
