import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pending_email_link_store.dart';
import '../auth_strings.dart';
import '../providers/auth_providers.dart';

/// Fallback screen shown when the app receives a valid-looking email
/// sign-in link but has no saved pending email on this device (e.g. the
/// user opened the link on a different device than the one that
/// requested it). Lets them confirm the email manually to finish signing
/// in, per the "email must match the address the link was sent to"
/// requirement of Firebase email link auth.
class CompleteEmailLinkScreen extends ConsumerStatefulWidget {
  const CompleteEmailLinkScreen({super.key, required this.emailLink});

  final String emailLink;

  @override
  ConsumerState<CompleteEmailLinkScreen> createState() => _CompleteEmailLinkScreenState();
}

class _CompleteEmailLinkScreenState extends ConsumerState<CompleteEmailLinkScreen> {
  final _emailController = TextEditingController();
  bool _busy = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = AuthStrings.invalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmailLink(
            email: email,
            emailLink: widget.emailLink,
          );
      await PendingEmailLinkStore().clear();
      // Auth state stream picks this up and the app root swaps to
      // HomeScreen automatically; just close this screen.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-action-code')) return AuthStrings.errorLinkInvalidOrUsed;
    if (msg.contains('expired-action-code')) return AuthStrings.errorLinkExpired;
    if (msg.contains('invalid-email')) return AuthStrings.invalidEmail;
    if (msg.contains('does not match')) return AuthStrings.errorEmailMismatch;
    return AuthStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AuthStrings.signInWithEmailLink)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AuthStrings.errorNoPendingEmail,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_busy,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _confirm(),
              decoration: const InputDecoration(
                labelText: AuthStrings.emailLabel,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AuthStrings.verify),
            ),
          ],
        ),
      ),
    );
  }
}
