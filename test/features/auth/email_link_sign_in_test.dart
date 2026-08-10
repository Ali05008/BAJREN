import 'package:bajren/features/auth/data/demo_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uses DemoAuthRepository (no real Firebase project needed) to exercise
/// the email-link sign-in contract every AuthRepository implementation
/// must satisfy: send -> recognize -> redeem-once -> reject reuse.
void main() {
  group('DemoAuthRepository email link sign-in', () {
    test('a freshly generated link is recognized as a sign-in link', () async {
      final repo = DemoAuthRepository();
      await repo.sendEmailSignInLink('user@example.com');

      final link = repo.debugPendingEmailLink;
      expect(link, isNotNull);
      expect(repo.isEmailSignInLink(link!), isTrue);
      expect(repo.isEmailSignInLink('https://example.com/not-a-link'), isFalse);
    });

    test('completes sign-in when email matches and code is correct', () async {
      final repo = DemoAuthRepository();
      await repo.sendEmailSignInLink('user@example.com');
      final link = repo.debugPendingEmailLink!;

      final user = await repo.signInWithEmailLink(
        email: 'user@example.com',
        emailLink: link,
      );

      expect(user.uid, 'demo-email-user@example.com');
      expect(repo.currentUser, isNotNull);
    });

    test('rejects sign-in when the email does not match the link recipient', () async {
      final repo = DemoAuthRepository();
      await repo.sendEmailSignInLink('user@example.com');
      final link = repo.debugPendingEmailLink!;

      expect(
        () => repo.signInWithEmailLink(email: 'attacker@example.com', emailLink: link),
        throwsA(isA<StateError>()),
      );
    });

    test('a link can only be redeemed once', () async {
      final repo = DemoAuthRepository();
      await repo.sendEmailSignInLink('user@example.com');
      final link = repo.debugPendingEmailLink!;

      await repo.signInWithEmailLink(email: 'user@example.com', emailLink: link);

      expect(
        () => repo.signInWithEmailLink(email: 'user@example.com', emailLink: link),
        throwsA(isA<StateError>()),
      );
    });

    test('signing in without a pending link throws', () async {
      final repo = DemoAuthRepository();

      expect(
        () => repo.signInWithEmailLink(
          email: 'user@example.com',
          emailLink: '${DemoAuthRepository.demoEmailLinkPrefix}whatever',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('signOut clears the session after an email-link sign-in', () async {
      final repo = DemoAuthRepository();
      await repo.sendEmailSignInLink('user@example.com');
      final link = repo.debugPendingEmailLink!;
      await repo.signInWithEmailLink(email: 'user@example.com', emailLink: link);

      await repo.signOut();

      expect(repo.currentUser, isNull);
    });
  });
}
