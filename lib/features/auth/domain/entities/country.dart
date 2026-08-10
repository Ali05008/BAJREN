/// A country entry for the phone number country picker.
///
/// This is deliberately a plain data class with a flat list, not a
/// package dependency, so more countries can be appended later with zero
/// structural change — just add another [Country] to [kArabCountries] (or
/// a future combined list).
class Country {
  final String nameAr;
  final String isoCode; // ISO 3166-1 alpha-2
  final String dialCode; // includes leading '+'
  final String flagEmoji;

  const Country({
    required this.nameAr,
    required this.isoCode,
    required this.dialCode,
    required this.flagEmoji,
  });
}

/// Arab countries, Saudi Arabia first (the default selection).
/// Non-Arab countries can be appended to a combined list later without
/// touching this one.
const List<Country> kArabCountries = [
  Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦'),
  Country(nameAr: 'الإمارات', isoCode: 'AE', dialCode: '+971', flagEmoji: '🇦🇪'),
  Country(nameAr: 'الكويت', isoCode: 'KW', dialCode: '+965', flagEmoji: '🇰🇼'),
  Country(nameAr: 'قطر', isoCode: 'QA', dialCode: '+974', flagEmoji: '🇶🇦'),
  Country(nameAr: 'البحرين', isoCode: 'BH', dialCode: '+973', flagEmoji: '🇧🇭'),
  Country(nameAr: 'عُمان', isoCode: 'OM', dialCode: '+968', flagEmoji: '🇴🇲'),
  Country(nameAr: 'اليمن', isoCode: 'YE', dialCode: '+967', flagEmoji: '🇾🇪'),
  Country(nameAr: 'العراق', isoCode: 'IQ', dialCode: '+964', flagEmoji: '🇮🇶'),
  Country(nameAr: 'الأردن', isoCode: 'JO', dialCode: '+962', flagEmoji: '🇯🇴'),
  Country(nameAr: 'لبنان', isoCode: 'LB', dialCode: '+961', flagEmoji: '🇱🇧'),
  Country(nameAr: 'سوريا', isoCode: 'SY', dialCode: '+963', flagEmoji: '🇸🇾'),
  Country(nameAr: 'فلسطين', isoCode: 'PS', dialCode: '+970', flagEmoji: '🇵🇸'),
  Country(nameAr: 'مصر', isoCode: 'EG', dialCode: '+20', flagEmoji: '🇪🇬'),
  Country(nameAr: 'السودان', isoCode: 'SD', dialCode: '+249', flagEmoji: '🇸🇩'),
  Country(nameAr: 'ليبيا', isoCode: 'LY', dialCode: '+218', flagEmoji: '🇱🇾'),
  Country(nameAr: 'تونس', isoCode: 'TN', dialCode: '+216', flagEmoji: '🇹🇳'),
  Country(nameAr: 'الجزائر', isoCode: 'DZ', dialCode: '+213', flagEmoji: '🇩🇿'),
  Country(nameAr: 'المغرب', isoCode: 'MA', dialCode: '+212', flagEmoji: '🇲🇦'),
  Country(nameAr: 'موريتانيا', isoCode: 'MR', dialCode: '+222', flagEmoji: '🇲🇷'),
  Country(nameAr: 'الصومال', isoCode: 'SO', dialCode: '+252', flagEmoji: '🇸🇴'),
  Country(nameAr: 'جيبوتي', isoCode: 'DJ', dialCode: '+253', flagEmoji: '🇩🇯'),
  Country(nameAr: 'جزر القمر', isoCode: 'KM', dialCode: '+269', flagEmoji: '🇰🇲'),
];

/// Strips non-digits and a single leading local trunk '0', then prefixes
/// the country's dial code, producing an E.164-formatted number
/// (e.g. Country(+966) + "0501234567" -> "+966501234567").
String toE164(Country country, String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'[^0-9]'), '');
  final trimmed = digits.startsWith('0') ? digits.substring(1) : digits;
  return '${country.dialCode}$trimmed';
}

/// Basic sanity check before sending an OTP: not empty, and the resulting
/// E.164 number falls within the ITU-T E.164 length bounds (max 15 digits
/// after the '+'). This is intentionally not exhaustive per-country
/// validation (no external phone-number library per project constraints).
bool isValidPhoneNumber(Country country, String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'[^0-9]'), '');
  final trimmed = digits.startsWith('0') ? digits.substring(1) : digits;
  if (trimmed.isEmpty) return false;
  final dialDigits = country.dialCode.replaceAll('+', '');
  final totalDigits = dialDigits.length + trimmed.length;
  return totalDigits >= 8 && totalDigits <= 15;
}
