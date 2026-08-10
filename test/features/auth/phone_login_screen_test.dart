import 'package:bajren/features/auth/data/demo_auth_repository.dart';
import 'package:bajren/features/auth/presentation/auth_strings.dart';
import 'package:bajren/features/auth/presentation/providers/auth_providers.dart';
import 'package:bajren/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bajren/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(DemoAuthRepository repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: PhoneLoginScreen()),
  );
}

void main() {
  testWidgets('shows an error for an implausibly short phone number', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text(AuthStrings.sendCode));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.invalidPhoneNumber), findsOneWidget);
  });

  testWidgets('defaults to Saudi Arabia dial code', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.text('+966'), findsOneWidget);
  });

  testWidgets('country picker lets you search and select a different country', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+966'));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.selectCountry), findsOneWidget);

    await tester.enterText(find.byKey(const Key('country_search_field')), 'مص');
    await tester.pumpAndSettle();

    expect(find.text('مصر'), findsOneWidget);
    await tester.tap(find.text('مصر'));
    await tester.pumpAndSettle();

    expect(find.text('+20'), findsOneWidget);
  });

  testWidgets('valid number navigates to the OTP screen', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0501234567');
    await tester.tap(find.text(AuthStrings.sendCode));
    // Bounded, not pumpAndSettle: landing on OtpVerificationScreen starts
    // its own live resend-cooldown Timer.periodic, which can make
    // pumpAndSettle hang waiting for a 'settled' state that never comes.
    await tester.pump();
    await tester.pump();

    expect(find.byType(OtpVerificationScreen), findsOneWidget);
    expect(find.textContaining('+966501234567'), findsOneWidget);
  });
}
