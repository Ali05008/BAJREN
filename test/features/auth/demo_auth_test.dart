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
}
