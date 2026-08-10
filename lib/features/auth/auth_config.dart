/// Central switch for which primary sign-in method the UI uses.
///
/// Phone OTP requires the Firebase Blaze (pay-as-you-go) plan. Until the
/// project is upgraded, [kActiveAuthMethod] stays [AuthMethod.emailLink] so
/// the app runs entirely on the free Spark plan. Phone OTP code, screens,
/// and Firebase configuration are NOT deleted — only unreached from the
/// main login flow. To re-enable phone sign-in later (after upgrading to
/// Blaze), flip this single value back to [AuthMethod.phone].
enum AuthMethod { emailLink, phone }

const AuthMethod kActiveAuthMethod = AuthMethod.emailLink;
