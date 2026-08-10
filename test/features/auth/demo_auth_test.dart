import 'package:bajren/features/auth/data/demo_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DemoAuthRepository anonymous sign-in yields uid', () async {
    final repo = DemoAuthRepository();
    final user = await repo.signInAnonymously();
    expect(user.uid, isNotEmpty);
    expect(user.isAnonymous, isTrue);
    expect(repo.currentUser?.uid, user.uid);
    await repo.signOut();
    expect(repo.currentUser, isNull);
    repo.dispose();
  });

  test('phone verification succeeds with the correct demo code', () async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');
    expect(result.verificationId, isNotNull);
    expect(result.isAutoVerified, isFalse);

    final user = await repo.confirmPhoneCode(
      verificationId: result.verificationId!,
      smsCode: DemoAuthRepository.demoOtpCode,
    );
    expect(user.uid, isNotEmpty);
    expect(repo.currentUser?.uid, user.uid);
    repo.dispose();
  });

  test('phone verification rejects an incorrect code', () async {
    final repo = DemoAuthRepository();
    final result = await repo.startPhoneVerification('+966501234567');

    expect(
      () => repo.confirmPhoneCode(
        verificationId: result.verificationId!,
        smsCode: '000000',
      ),
      throwsA(isA<StateError>()),
    );
    expect(repo.currentUser, isNull);
    repo.dispose();
  });

  test('phone verification rejects a stale/unknown verification id', () async {
    final repo = DemoAuthRepository();
    await repo.startPhoneVerification('+966501234567');

    expect(
      () => repo.confirmPhoneCode(
        verificationId: 'some-other-session-id',
        smsCode: DemoAuthRepository.demoOtpCode,
      ),
      throwsA(isA<StateError>()),
    );
    repo.dispose();
  });

  test('confirming without ever starting verification fails', () async {
    final repo = DemoAuthRepository();
    expect(
      () => repo.confirmPhoneCode(
        verificationId: 'never-started',
        smsCode: DemoAuthRepository.demoOtpCode,
      ),
      throwsA(isA<StateError>()),
    );
    repo.dispose();
  });

  test('starting a new verification invalidates the previous session id', () async {
    final repo = DemoAuthRepository();
    final first = await repo.startPhoneVerification('+966501234567');
    final second = await repo.startPhoneVerification('+966501234567');

    expect(first.verificationId, isNot(second.verificationId));
    expect(
      () => repo.confirmPhoneCode(
        verificationId: first.verificationId!,
        smsCode: DemoAuthRepository.demoOtpCode,
      ),
      throwsA(isA<StateError>()),
    );
    repo.dispose();
  });
}
