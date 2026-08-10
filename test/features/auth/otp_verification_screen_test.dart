import 'package:bajren/features/auth/data/demo_auth_repository.dart';
import 'package:bajren/features/auth/domain/entities/country.dart';
import 'package:bajren/features/auth/presentation/auth_strings.dart';
import 'package:bajren/features/auth/presentation/providers/auth_providers.dart';
import 'package:bajren/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _saudi = Country(nameAr: 'السعودية', isoCode: 'SA', dialCode: '+966', flagEmoji: '🇸🇦');

void main() {
  testWidgets('wrong code shows an error and does not sign in', (tester) async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: OtpVerificationScreen(
            phoneE164: '+966501234567',
            verificationId: result.verificationId!,
            country: _saudi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text(AuthStrings.verify));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.errorInvalidOtp), findsOneWidget);
    expect(repo.currentUser, isNull);
  });

  testWidgets('correct demo code signs the user in', (tester) async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: OtpVerificationScreen(
            phoneE164: '+966501234567',
            verificationId: result.verificationId!,
            country: _saudi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), DemoAuthRepository.demoOtpCode);
    await tester.tap(find.text(AuthStrings.verify));
    await tester.pumpAndSettle();

    expect(repo.currentUser, isNotNull);
  });

  testWidgets('resend is disabled during the cooldown, then enabled', (tester) async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: OtpVerificationScreen(
            phoneE164: '+966501234567',
            verificationId: result.verificationId!,
            country: _saudi,
          ),
        ),
      ),
    );
    await tester.pump();

    // Immediately after showing the screen, resend should be on cooldown.
    expect(find.text(AuthStrings.resendCode), findsNothing);

    // Fast-forward past the 60s cooldown.
    await tester.pump(const Duration(seconds: 61));

    expect(find.text(AuthStrings.resendCode), findsOneWidget);
  });

  testWidgets('edit phone number button pops the screen', (tester) async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        phoneE164: '+966501234567',
                        verificationId: result.verificationId!,
                        country: _saudi,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpVerificationScreen), findsOneWidget);
    await tester.tap(find.text(AuthStrings.editPhoneNumber));
    await tester.pumpAndSettle();

    expect(find.byType(OtpVerificationScreen), findsNothing);
  });
}
