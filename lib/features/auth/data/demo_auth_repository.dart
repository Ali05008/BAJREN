import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/entities/phone_verification_result.dart';

/// Local-only auth for CI / demo when Firebase is not configured.
/// Does NOT provide real multi-device signaling, and does NOT send real
/// SMS — phone verification is simulated with a fixed demo code so the
/// flow (and its tests) can run without a real Firebase project.
class DemoAuthRepository implements AuthRepository {
  static const demoOtpCode = '123456';

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  final _uuid = const Uuid();

  String? _pendingVerificationId;
  String? _pendingPhone;

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

  @override
  Future<PhoneVerificationResult> startPhoneVerification(
    String e164Phone,
  ) async {
    _pendingPhone = e164Phone;
    _pendingVerificationId = 'demo-verification-${_uuid.v4().substring(0, 8)}';
    return PhoneVerificationResult(verificationId: _pendingVerificationId);
  }

  @override
  Future<AuthUser> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (_pendingVerificationId == null ||
        verificationId != _pendingVerificationId) {
      throw StateError('Verification session expired. Request a new code.');
    }
    if (smsCode != demoOtpCode) {
      throw StateError('Invalid verification code.');
    }
    _user = AuthUser(uid: 'demo-phone-$_pendingPhone', displayName: _pendingPhone);
    _controller.add(_user);
    return _user!;
  }

  void dispose() {
    _controller.close();
  }
}
