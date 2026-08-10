import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pending_email_link_store.dart';
import '../auth_strings.dart';
import '../providers/auth_providers.dart';

const _resendCooldownSeconds = 60;

/// Shown right after a sign-in link email was sent. Saves the address
/// locally so the link can be redeemed later even if the app process was
/// killed in the meantime, and offers a rate-limited "resend" action.
class EmailLinkSentScreen extends ConsumerStatefulWidget {
  const EmailLinkSentScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailLinkSentScreen> createState() => _EmailLinkSentScreenState();
}

class _EmailLinkSentScreenState extends ConsumerState<EmailLinkSentScreen> {
  final _store = PendingEmailLinkStore();
  Timer? _timer;
  int _secondsLeft = _resendCooldownSeconds;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    // Save immediately so a link opened after the app is killed and
    // relaunched can still be completed.
    _store.save(widget.email);
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _secondsLeft = _resendCooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = 0;
          t.cancel();
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  Future<void> _resend() async {
    // Guard against double-tap and against resending while the cooldown
    // is still active.
    if (_resending || _secondsLeft > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailSignInLink(widget.email);
      await _store.save(widget.email);
      if (!mounted) return;
      setState(() => _info = AuthStrings.linkSentTitle);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('too-many-requests')) return AuthStrings.errorTooManyRequests;
    if (msg.contains('network')) return AuthStrings.errorNetwork;
    return AuthStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AuthStrings.linkSentTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 56, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              AuthStrings.linkSentTo(widget.email),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_info != null) ...[
              const SizedBox(height: 12),
              Text(_info!, style: const TextStyle(color: Colors.teal)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _secondsLeft > 0
                            ? AuthStrings.resendLinkIn(_secondsLeft)
                            : AuthStrings.resendLink,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AuthStrings.editEmail),
            ),
          ],
        ),
      ),
    );
  }
}
