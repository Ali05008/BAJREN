/// User-facing strings for the phone sign-in flow.
///
/// Deliberately NOT using intl/gen-l10n yet (out of scope for this stage
/// per instructions), but every string a user can see lives here instead
/// of being inlined in widgets — so wiring up real localization later is
/// a mechanical move, not a rewrite.
class AuthStrings {
  AuthStrings._();

  static const signInWithPhone = 'تسجيل الدخول برقم الجوال';
  static const phoneNumberLabel = 'رقم الجوال';
  static const phoneNumberHint = 'ادخل رقم جوالك';
  static const selectCountry = 'اختر الدولة';
  static const searchCountryHint = 'ابحث عن دولة';
  static const sendCode = 'إرسال الرمز';
  static const invalidPhoneNumber = 'رقم الجوال غير صحيح';

  static const otpTitle = 'أدخل رمز التحقق';
  static String otpSentTo(String phone) => 'تم إرسال رمز إلى $phone';
  static const otpHint = 'رمز التحقق';
  static const verify = 'تحقق';
  static const resendCode = 'إعادة إرسال الرمز';
  static String resendIn(int seconds) => 'إعادة الإرسال بعد $seconds ثانية';
  static const editPhoneNumber = 'تعديل رقم الجوال';

  static const errorInvalidOtp = 'رمز التحقق غير صحيح';
  static const errorOtpExpired = 'انتهت صلاحية الرمز، اطلب رمزًا جديدًا';
  static const errorTooManyRequests = 'محاولات كثيرة، حاول لاحقًا';
  static const errorGeneric = 'حدث خطأ، حاول مرة أخرى';
  static const errorNetwork = 'تحقق من اتصال الإنترنت وحاول مرة أخرى';

  // Email Link (passwordless) sign-in — active while kActiveAuthMethod ==
  // AuthMethod.emailLink (see auth_config.dart).
  static const signInWithEmailLink = 'تسجيل الدخول عبر البريد الإلكتروني';
  static const emailLabel = 'البريد الإلكتروني';
  static const emailHint = 'ادخل بريدك الإلكتروني';
  static const sendLink = 'إرسال رابط الدخول';
  static const invalidEmail = 'البريد الإلكتروني غير صحيح';

  static const linkSentTitle = 'تم إرسال رابط الدخول';
  static String linkSentTo(String email) =>
      'أرسلنا رابط تسجيل الدخول إلى $email. افتح الرابط من نفس هذا الجهاز لإكمال تسجيل الدخول.';
  static const openEmailApp = 'فتح تطبيق البريد';
  static const resendLink = 'إعادة إرسال الرابط';
  static String resendLinkIn(int seconds) => 'يمكنك إعادة الإرسال بعد $seconds ثانية';
  static const editEmail = 'تعديل البريد الإلكتروني';

  static const verifyingLink = 'جارٍ التحقق من الرابط...';
  static const errorLinkInvalidOrUsed =
      'هذا الرابط غير صالح أو تم استخدامه من قبل. اطلب رابطًا جديدًا.';
  static const errorLinkExpired = 'انتهت صلاحية الرابط، اطلب رابطًا جديدًا';
  static const errorEmailMismatch =
      'افتح الرابط من نفس الجهاز الذي طلبت منه رابط الدخول، أو أدخل نفس البريد المستخدم';
  static const errorNoPendingEmail =
      'لم نجد طلب تسجيل دخول سابق على هذا الجهاز. أدخل بريدك لإكمال الدخول.';
  static const signInSuccess = 'تم تسجيل الدخول بنجاح';
}
