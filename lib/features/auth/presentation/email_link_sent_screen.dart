import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/auth_widgets.dart';

/// Shown right after AuthService.sendSignInLinkToEmail succeeds.
/// The actual "complete sign-in" step happens elsewhere — typically in
/// a deep-link handler (matching your existing EmailLinkDeepLinkHandler /
/// PendingEmailLinkStore setup) that calls
/// AuthService.signInWithEmailLink once the user taps the link they
/// received by email and the app is reopened via that link.
class EmailLinkSentScreen extends StatefulWidget {
  const EmailLinkSentScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailLinkSentScreen> createState() => _EmailLinkSentScreenState();
}

class _EmailLinkSentScreenState extends State<EmailLinkSentScreen> {
  final _authService = AuthService();
  bool _isResending = false;

  Future<void> _resendLink() async {
    setState(() => _isResending = true);
    try {
      await _authService.sendSignInLinkToEmail(widget.email);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(),
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandColors.surfaceBorder),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: BrandColors.cyan, size: 30),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.emailLinkSentTitle,
                style: const TextStyle(
                  color: BrandColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.emailLinkSentMessage,
                style: const TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  color: BrandColors.cyan,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: l10n.resendLink,
                isLoading: _isResending,
                onPressed: _resendLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
