import '../auth_user.dart';

/// Outcome of [AuthRepository.startPhoneVerification].
///
/// Exactly one of [verificationId] or [autoVerifiedUser] is non-null:
/// - [verificationId] is set when an SMS code was sent and the caller
///   should show the OTP entry screen.
/// - [autoVerifiedUser] is set on the rare case where the platform
///   auto-retrieved and verified the SMS code before the user had to type
///   anything (Android instant verification) — sign-in already happened.
class PhoneVerificationResult {
  final String? verificationId;
  final AuthUser? autoVerifiedUser;

  const PhoneVerificationResult({this.verificationId, this.autoVerifiedUser});

  bool get isAutoVerified => autoVerifiedUser != null;
}
