import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/country.dart';
import '../auth_strings.dart';
import '../providers/auth_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneE164,
    required this.verificationId,
    required this.country,
  });

  final String phoneE164;
  final String verificationId;
  final Country country;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _resendCooldownSeconds = 60;

  late String _verificationId;
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  Timer? _timer;
  int _secondsLeft = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(widget.phoneE164);
      if (!mounted) return;
      setState(() => _busy = false);

      if (result.isAutoVerified) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      final newId = result.verificationId;
      if (newId != null) {
        setState(() => _verificationId = newId);
        _startResendTimer();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmPhoneCode(
            verificationId: _verificationId,
            smsCode: code,
          );
      if (!mounted) return;
      // Sign-in succeeded — authStateProvider will swap the app to the
      // home screen; unwind this screen and the phone-entry screen below
      // it so the user doesn't land back on them via system back.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid-verification-code') || msg.contains('invalid verification code')) {
      return AuthStrings.errorInvalidOtp;
    }
    if (msg.contains('session-expired') || msg.contains('expired')) {
      return AuthStrings.errorOtpExpired;
    }
    if (msg.contains('too-many-requests') || msg.contains('quota-exceeded')) {
      return AuthStrings.errorTooManyRequests;
    }
    if (msg.contains('network')) {
      return AuthStrings.errorNetwork;
    }
    return AuthStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AuthStrings.otpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AuthStrings.otpSentTo(widget.phoneE164)),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '••••••',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verify,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(AuthStrings.verify),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: (_secondsLeft > 0 || _busy) ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? AuthStrings.resendIn(_secondsLeft)
                    : AuthStrings.resendCode,
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text(AuthStrings.editPhoneNumber),
            ),
          ],
        ),
      ),
    );
  }
}
