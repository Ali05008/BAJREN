import 'package:bajren/features/auth/data/demo_auth_repository.dart';
import 'package:bajren/features/auth/presentation/auth_strings.dart';
import 'package:bajren/features/auth/presentation/providers/auth_providers.dart';
import 'package:bajren/features/auth/presentation/screens/email_link_sent_screen.dart';
import 'package:bajren/features/auth/presentation/screens/email_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(DemoAuthRepository repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: EmailLoginScreen()),
  );
}

void main() {
  testWidgets('send button stays disabled for an invalid email', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows an explicit error for an invalid email on submit attempt', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.invalidEmail), findsOneWidget);
  });

  testWidgets('sending a valid email navigates to the "link sent" screen', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AuthStrings.sendLink));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLinkSentScreen), findsOneWidget);
    expect(find.text(AuthStrings.linkSentTo('user@example.com')), findsOneWidget);
  });

  testWidgets('resend button is disabled during the cooldown window', (tester) async {
    await tester.pumpWidget(_wrap(DemoAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AuthStrings.sendLink));
    await tester.pumpAndSettle();

    final resendButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(resendButton.onPressed, isNull);
  });
}
