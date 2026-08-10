import 'package:bajren/features/auth/domain/entities/country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kArabCountries has exactly the 22 requested countries', () {
    expect(kArabCountries.length, 22);
  });

  test('Saudi Arabia is first (the default selection)', () {
    expect(kArabCountries.first.isoCode, 'SA');
    expect(kArabCountries.first.dialCode, '+966');
  });

  test('every country has a non-empty name, flag, and dial code starting with +', () {
    for (final c in kArabCountries) {
      expect(c.nameAr, isNotEmpty);
      expect(c.flagEmoji, isNotEmpty);
      expect(c.dialCode, startsWith('+'));
      expect(c.isoCode.length, 2);
    }
  });

  test('all iso codes are unique', () {
    final codes = kArabCountries.map((c) => c.isoCode).toSet();
    expect(codes.length, kArabCountries.length);
  });

  test('toE164 strips a single leading local trunk zero', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(toE164(saudi, '0501234567'), '+966501234567');
  });

  test('toE164 works without a leading zero too', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(toE164(saudi, '501234567'), '+966501234567');
  });

  test('toE164 strips spaces and dashes', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(toE164(saudi, '050-123 4567'), '+966501234567');
  });

  test('isValidPhoneNumber accepts a plausible Saudi number', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(isValidPhoneNumber(saudi, '0501234567'), isTrue);
  });

  test('isValidPhoneNumber rejects an empty number', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(isValidPhoneNumber(saudi, ''), isFalse);
    expect(isValidPhoneNumber(saudi, '   '), isFalse);
  });

  test('isValidPhoneNumber rejects an implausibly short number', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(isValidPhoneNumber(saudi, '123'), isFalse);
  });

  test('isValidPhoneNumber rejects an implausibly long number', () {
    const saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');
    expect(isValidPhoneNumber(saudi, '1234567890123456789'), isFalse);
  });
}
