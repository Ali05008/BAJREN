import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<AuthUser> signInAnonymously();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<String?> getIdToken({bool forceRefresh = false});
}
