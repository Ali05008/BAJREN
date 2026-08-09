import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Local-only auth for CI / demo when Firebase is not configured.
/// Does NOT provide real multi-device signaling.
class DemoAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  final _uuid = const Uuid();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInAnonymously() async {
    _user = AuthUser(uid: 'demo-${_uuid.v4().substring(0, 8)}', isAnonymous: true);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    _user = AuthUser(uid: 'demo-$email', displayName: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> registerWithEmail(String email, String password) {
    return signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => null;

  void dispose() {
    _controller.close();
  }
}
