import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/auth_widgets.dart';

/// BAJREN account creation screen.
/// After Firebase Auth account creation succeeds, the caller is expected
/// to also write a matching profile record (name, username, bio, avatar,
/// createdAt, verification level, etc.) to your database — that step
/// belongs to the "Profile" phase and isn't duplicated here to keep this
/// screen focused strictly on authentication.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() => _errorMessage = l10n.errorMustAgreeTerms);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = l10n.errorPasswordMismatch);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // TODO: write the profile record here (name, username, bio,
      // default avatar, createdAt) to your users database — this is
      // intentionally left out since it belongs to the Profile phase
      // and depends on your exact schema (Firestore vs RTDB, field
      // names, uniqueness checks for `username`, etc).
    } on Exception catch (e) {
      setState(() => _errorMessage = _mapAuthError(e, l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(Exception e, AppLocalizations l10n) {
    final code = e.toString();
    if (code.contains('invalid-email')) return l10n.errorInvalidEmail;
    if (code.contains('email-already-in-use')) return l10n.errorEmailInUse;
    if (code.contains('weak-password')) return l10n.errorWeakPassword;
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: BrandColors.textPrimary, size: 18),
                    ),
                    const Spacer(),
                    const LanguageToggleRow(),
                  ],
                ),
                const SizedBox(height: 8),
                const BrandLogo(),
                const SizedBox(height: 24),
                Text(
                  l10n.registerTitle,
                  style: const TextStyle(
                    color: BrandColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.registerSubtitle,
                  style: const TextStyle(
                    color: BrandColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _nameController,
                  label: l10n.fullNameLabel,
                  hint: l10n.fullNameHint,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.errorFieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  label: l10n.emailLabel,
                  hint: l10n.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.errorFieldRequired;
                    }
                    if (!value.contains('@')) return l10n.errorInvalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _usernameController,
                  label: l10n.usernameLabel,
                  hint: l10n.usernameHint,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.errorFieldRequired;
                    }
                    if (value.length < 6) return l10n.errorWeakPassword;
                    return null;
                  },
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
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: l10n.confirmPasswordLabel,
                  hint: l10n.confirmPasswordHint,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => (value == null || value.isEmpty)
                      ? l10n.errorFieldRequired
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: BrandColors.textSecondary,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: BrandColors.cyan,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: BrandColors.textSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(text: l10n.termsAgreementPrefix),
                            TextSpan(
                              text: l10n.termsAndConditions,
                              style: const TextStyle(
                                color: BrandColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: l10n.andPrivacyPolicy),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: BrandColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                GradientButton(
                  label: l10n.registerButton,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.haveAccountPrompt,
                      style: const TextStyle(color: BrandColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.loginLink,
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
