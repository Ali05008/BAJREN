import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/username_resolver.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'register_screen.dart';
import 'email_link_sent_screen.dart';
import 'widgets/auth_widgets.dart';

/// BAJREN sign-in screen.
/// Supports three coexisting sign-in paths:
///  - Email or username + password
///  - Google Sign-In
///  - Passwordless email link ("magic link")
///
/// This file replaces the previous placeholder login screen
/// (the "Firebase ready — real Auth + Signaling" test screen).
/// Wire it in as the entry point of your unauthenticated route,
/// e.g. inside an AuthGate that listens to AuthService.authStateChanges.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  final _usernameResolver = UsernameResolver();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final identifier = _identifierController.text.trim();
      final email =
          await _usernameResolver.resolveIdentifierToEmail(identifier);

      if (email == null) {
        setState(() => _errorMessage = l10n.errorUserNotFound);
        return;
      }

      await _authService.signInWithEmail(
        email: email,
        password: _passwordController.text,
      );
      // Successful sign-in navigation is expected to be handled by an
      // authStateChanges listener higher up (e.g. an AuthGate wrapping
      // the app's root), not from here.
    } on Exception catch (e) {
      setState(() => _errorMessage = _mapAuthError(e, l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
    } on Exception catch (e) {
      setState(() => _errorMessage = _mapAuthError(e, l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLinkSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    final identifier = _identifierController.text.trim();
    if (!identifier.contains('@')) {
      setState(() => _errorMessage = l10n.errorInvalidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendSignInLinkToEmail(identifier);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailLinkSentScreen(email: identifier),
        ),
      );
    } on Exception catch (e) {
      setState(() => _errorMessage = _mapAuthError(e, l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(Exception e, AppLocalizations l10n) {
    final code = e.toString();
    if (code.contains('invalid-email')) return l10n.errorInvalidEmail;
    if (code.contains('user-not-found')) return l10n.errorUserNotFound;
    if (code.contains('wrong-password')) return l10n.errorWrongPassword;
    return l10n.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LanguageToggleRow(),
                const SizedBox(height: 24),
                const BrandLogo(),
                const SizedBox(height: 32),
                Text(
                  l10n.loginTitle,
                  style: const TextStyle(
                    color: BrandColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  style: const TextStyle(
                    color: BrandColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _identifierController,
                  label: l10n.emailOrUsernameLabel,
                  hint: l10n.emailOrUsernameHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.errorFieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: l10n.passwordLabel,
                  hint: l10n.passwordHint,
                  obscureText: _obscurePassword,
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.errorFieldRequired
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: BrandColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final email = _identifierController.text.trim();
                            if (email.contains('@')) {
                              await _authService.sendPasswordResetEmail(email);
                            }
                          },
                    child: Text(
                      l10n.forgotPassword,
                      style: const TextStyle(color: BrandColors.cyan),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: BrandColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                GradientButton(
                  label: l10n.loginButton,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: BrandColors.surfaceBorder),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.orDivider,
                        style: const TextStyle(color: BrandColors.textSecondary),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: BrandColors.surfaceBorder),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedIconButton(
                  label: l10n.continueWithGoogle,
                  icon: const GoogleGlyph(),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ),
                const SizedBox(height: 12),
                OutlinedIconButton(
                  label: l10n.signInWithLinkButton,
                  icon: const Icon(Icons.link_rounded,
                      color: BrandColors.cyan, size: 20),
                  onPressed: _isLoading ? null : _handleEmailLinkSignIn,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.noAccountPrompt,
                      style: const TextStyle(color: BrandColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.createAccountLink,
                        style: const TextStyle(
                          color: BrandColors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
