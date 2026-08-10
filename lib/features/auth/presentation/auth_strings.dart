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
}
