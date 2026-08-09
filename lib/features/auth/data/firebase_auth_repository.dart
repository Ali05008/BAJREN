import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthUser _map(User user) => AuthUser(
        uid: user.uid,
        displayName: user.displayName ?? user.email,
        isAnonymous: user.isAnonymous,
      );

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map((u) => u == null ? null : _map(u));
  }

  @override
  AuthUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _map(u);
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw StateError('Anonymous sign-in failed');
    }
    return _map(user);
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) throw StateError('Email sign-in failed');
    return _map(user);
  }

  @override
  Future<AuthUser> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) throw StateError('Registration failed');
    return _map(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }
}
