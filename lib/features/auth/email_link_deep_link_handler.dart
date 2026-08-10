import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'data/firebase_auth_repository.dart';
import 'data/pending_email_link_store.dart';
import 'presentation/auth_strings.dart';
import 'presentation/screens/complete_email_link_screen.dart';

/// Listens for incoming Android App Links and completes email-link
/// sign-in when one arrives. Works whether the app was already running
/// or was launched cold by tapping the link.
///
/// Deliberately does NOT log the link itself (or any part of it) — it
/// contains a one-time sign-in code (oobCode) that must be treated as a
/// secret-equivalent value.
class EmailLinkDeepLinkHandler {
  EmailLinkDeepLinkHandler({
    required this.navigatorKey,
    required this.messengerKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  final _appLinks = AppLinks();
  final _store = PendingEmailLinkStore();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    // Cold start: app was launched by tapping the link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (_) {
      // No initial link, or platform channel not ready yet — ignore.
    }

    // Warm: app was already running when the link was opened.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (_) {
        // Never crash the app over a malformed incoming link.
      },
    );
  }

  Future<void> _handle(Uri uri) async {
    final link = uri.toString();

    // Only used for a coarse recognition check — never log the value.
    final repo = FirebaseAuthRepository();
    if (!repo.isEmailSignInLink(link)) {
      return; // Not an auth link; some other deep link the app may add later.
    }

    final savedEmail = await _store.read();

    if (savedEmail == null || savedEmail.isEmpty) {
      // Opened on a different device than the one that requested the
      // link — ask the user to confirm their email to finish.
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CompleteEmailLinkScreen(emailLink: link),
        ),
      );
      return;
    }

    try {
      await repo.signInWithEmailLink(email: savedEmail, emailLink: link);
      await _store.clear();
      // Auth state stream updates automatically; app root swaps to
      // HomeScreen on its own.
    } catch (e) {
      developer.log('Email link sign-in failed', name: 'EmailLinkDeepLinkHandler');
      _showError(_friendlyError(e));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-action-code')) return AuthStrings.errorLinkInvalidOrUsed;
    if (msg.contains('expired-action-code')) return AuthStrings.errorLinkExpired;
    if (msg.contains('does not match')) return AuthStrings.errorEmailMismatch;
    return AuthStrings.errorGeneric;
  }

  void _showError(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}
