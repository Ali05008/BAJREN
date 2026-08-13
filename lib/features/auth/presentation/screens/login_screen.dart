import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/firebase_ready.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth_config.dart';
import '../../data/google_auth_service.dart';
import '../auth_strings.dart';
import '../providers/auth_providers.dart';
import '../username_resolver.dart';
import 'email_login_screen.dart';
import 'phone_login_screen.dart';

/// BAJREN sign-in / registration screen.
///
/// Supports three coexisting ways in, matching the existing
/// AuthRepository + AuthMethod setup:
///  - Email OR username + password (via [UsernameResolver] for the
///    username case, then AuthRepository.signInWithEmail)
///  - Google Sign-In (via the standalone [GoogleAuthService], which
///    updates the same FirebaseAuth instance AuthRepository listens to)
///  - Passwordless email link (existing EmailLoginScreen flow, kept
///    exactly as before via AuthStrings.signInWithEmailLink)
///
/// Arabic is the app's official language; English is offered as a
/// secondary option via the toggle in the top-right corner.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Sign-in fields
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // Register-only fields
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isArabic = true;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;

  final _usernameResolver = UsernameResolver();
  final _googleAuthService = GoogleAuthService();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final identifier = _identifierController.text.trim();
      final email = await _usernameResolver.resolveIdentifierToEmail(identifier);
      if (email == null) {
        throw Exception(_t('لا يوجد حساب بهذا البريد أو اسم المستخدم',
            'No account found with this email or username'));
      }
      await ref.read(authRepositoryProvider).signInWithEmail(
            email,
            _passwordController.text,
          );
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error =
          _t('كلمتا المرور غير متطابقتين', 'Passwords do not match'));
      return;
    }
    await _run(() async {
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();

      final user = await ref.read(authRepositoryProvider).registerWithEmail(
            email,
            _passwordController.text,
          );

      // Lightweight placeholder profile write (username + email only).
      // The full profile record (name, bio, avatar, verification level)
      // is written during the Profile phase.
      await _usernameResolver.saveBasicProfile(
        uid: user.uid,
        username: username,
        email: email,
      );
    });
  }

  Future<void> _handleGoogleSignIn() async {
    await _run(() async {
      await _googleAuthService.signIn();
      // No manual navigation needed: FirebaseAuth's authStateChanges()
      // (already wired through authStateProvider) picks this up and the
      // app's root MaterialApp switches to AppShell automatically.
    });
  }

  String _t(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.nearBlack,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _isArabic = !_isArabic),
                        icon: const Icon(Icons.language_rounded,
                            color: Colors.white70, size: 18),
                        label: Text(
                          _isArabic ? 'English' : 'العربية',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.cyan, AppColors.purple],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'B',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isRegisterMode
                        ? _t('إنشاء حساب جديد', 'Create Account')
                        : _t('تسجيل الدخول', 'Sign In'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!firebaseReady)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        _t(
                          'وضع تجريبي — بدون Firebase',
                          'Demo mode — no Firebase',
                        ),
                        style: const TextStyle(
                            color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // --- Primary passwordless CTA (unchanged behavior) ---
                  if (kActiveAuthMethod == AuthMethod.emailLink)
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailLoginScreen(),
                                ),
                              ),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: Text(AuthStrings.signInWithEmailLink),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PhoneLoginScreen(),
                                ),
                              ),
                      icon: const Icon(Icons.phone_android),
                      label: Text(AuthStrings.signInWithPhone),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(_t('أو', 'or'),
                            style: const TextStyle(color: Colors.white54)),
                      ),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Google Sign-In ---
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Text('G',
                          style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      label: Text(
                        _t('المتابعة عبر جوجل', 'Continue with Google'),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Email/username + password form ---
                  if (_isRegisterMode) ...[
                    _field(
                      controller: _emailController,
                      label: _t('البريد الإلكتروني', 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return _t('هذا الحقل مطلوب', 'Required');
                        }
                        if (!v.contains('@')) {
                          return _t('بريد إلكتروني غير صحيح', 'Invalid email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _usernameController,
                      label: _t('اسم المستخدم', 'Username'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? _t('هذا الحقل مطلوب', 'Required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _field(
                      controller: _identifierController,
                      label: _t(
                          'البريد الإلكتروني أو اسم المستخدم',
                          'Email or username'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? _t('هذا الحقل مطلوب', 'Required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _field(
                    controller: _passwordController,
                    label: _t('كلمة المرور', 'Password'),
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.isEmpty)
                        ? _t('هذا الحقل مطلوب', 'Required')
                        : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 12),
                    _field(
                      controller: _confirmPasswordController,
                      label: _t('تأكيد كلمة المرور', 'Confirm password'),
                      obscureText: _obscurePassword,
                      validator: (v) => (v == null || v.isEmpty)
                          ? _t('هذا الحقل مطلوب', 'Required')
                          : null,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : (_isRegisterMode ? _handleRegister : _handleSignIn),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.cyan,
                    ),
                    child: Text(
                      _busy
                          ? _t('جارٍ التحميل…', 'Please wait…')
                          : (_isRegisterMode
                              ? _t('إنشاء الحساب', 'Create Account')
                              : _t('دخول', 'Sign In')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode
                            ? _t('لديك حساب بالفعل؟', 'Already have an account?')
                            : _t('ليس لديك حساب؟', "Don't have an account?"),
                        style: const TextStyle(color: Colors.white54),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _error = null;
                                }),
                        child: Text(
                          _isRegisterMode
                              ? _t('سجّل الدخول', 'Sign in')
                              : _t('أنشئ حسابًا', 'Create one'),
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await ref
                                    .read(authRepositoryProvider)
                                    .signInAnonymously();
                              }),
                      child: Text(
                        _t('المتابعة كزائر', 'Continue anonymously'),
                        style: const TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppColors.darkSurface,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
      ),
    );
  }
}
