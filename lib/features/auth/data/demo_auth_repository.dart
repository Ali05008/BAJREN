import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/entities/phone_verification_result.dart';

/// Local-only auth for CI / demo when Firebase is not configured.
/// Does NOT provide real multi-device signaling, does NOT send real SMS,
/// and does NOT send real email — both phone and email-link verification
/// are simulated so the flows (and their tests) can run without a real
/// Firebase project.
class DemoAuthRepository implements AuthRepository {
  static const demoOtpCode = '123456';

  /// Deterministic fake link so tests can call [isEmailSignInLink] /
  /// [signInWithEmailLink] without a real Firebase project.
  static const demoEmailLinkPrefix = 'https://demo.bajren/finishSignIn?oobCode=';

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  final _uuid = const Uuid();

  String? _pendingVerificationId;
  String? _pendingPhone;

  String? _pendingEmailForLink;
  String? _pendingEmailLinkCode;

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

  @override
  Future<void> sendEmailSignInLink(String email) async {
    _pendingEmailForLink = email.trim();
    _pendingEmailLinkCode = _uuid.v4();
  }

  @override
  bool isEmailSignInLink(String link) {
    return link.startsWith(demoEmailLinkPrefix);
  }

  /// Test-only: the full simulated link matching the most recent
  /// [sendEmailSignInLink] call, or null if none is pending / it was
  /// already redeemed. Lets unit/widget tests simulate "opening the
  /// email link" without a real OS-level deep link. Not part of
  /// [AuthRepository] — only the demo implementation exposes it.
  String? get debugPendingEmailLink {
    if (_pendingEmailLinkCode == null) return null;
    return '$demoEmailLinkPrefix$_pendingEmailLinkCode';
  }

  @override
  Future<AuthUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    if (_pendingEmailForLink == null || _pendingEmailLinkCode == null) {
      throw StateError('No pending email link. Request a new link.');
    }
    if (email.trim() != _pendingEmailForLink) {
      throw StateError('Email does not match the address the link was sent to.');
    }
    if (!emailLink.endsWith(_pendingEmailLinkCode!)) {
      throw StateError('This link is invalid or has already been used.');
    }
    _user = AuthUser(uid: 'demo-email-$email', displayName: email);
    _controller.add(_user);
    // A link can only be redeemed once.
    _pendingEmailForLink = null;
    _pendingEmailLinkCode = null;
    return _user!;
  }

  void dispose() {
    _controller.close();
  }
}
