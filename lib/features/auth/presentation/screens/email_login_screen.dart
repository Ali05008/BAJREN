import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_strings.dart';
import '../providers/auth_providers.dart';
import 'email_link_sent_screen.dart';

/// Entry point for passwordless "magic link" sign-in.
///
/// Active while `kActiveAuthMethod == AuthMethod.emailLink` (see
/// auth_config.dart). Does not touch Phone OTP code or screens.
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValidEmail => _emailRegex.hasMatch(_emailController.text.trim());

  Future<void> _sendLink() async {
    // Guard against double-tap / repeat submission while a request is
    // already in flight.
    if (_sending) return;
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = AuthStrings.invalidEmail);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailSignInLink(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailLinkSentScreen(email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-email')) return AuthStrings.invalidEmail;
    if (msg.contains('too-many-requests')) return AuthStrings.errorTooManyRequests;
    if (msg.contains('network')) return AuthStrings.errorNetwork;
    return AuthStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AuthStrings.signInWithEmailLink)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 56),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_sending,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendLink(),
              decoration: InputDecoration(
                labelText: AuthStrings.emailLabel,
                hintText: AuthStrings.emailHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (_sending || !_isValidEmail) ? null : _sendLink,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AuthStrings.sendLink),
            ),
          ],
        ),
      ),
    );
  }
}
