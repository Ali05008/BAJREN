import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/country.dart';
import '../auth_strings.dart';
import '../providers/auth_providers.dart';
import '../widgets/country_picker_sheet.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  Country _country = kArabCountries.first;
  final _phoneController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context);
    if (picked != null) {
      setState(() => _country = picked);
    }
  }

  Future<void> _sendCode() async {
    if (!isValidPhoneNumber(_country, _phoneController.text)) {
      setState(() => _error = AuthStrings.invalidPhoneNumber);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final e164 = toE164(_country, _phoneController.text);
    try {
      final result =
          await ref.read(authRepositoryProvider).startPhoneVerification(e164);
      if (!mounted) return;
      setState(() => _busy = false);

      if (result.isAutoVerified) {
        // Sign-in already completed (Android instant verification).
        // authStateProvider will pick this up and swap to the home
        // screen automatically; just unwind any pushed routes.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      final verificationId = result.verificationId;
      if (verificationId == null) return;
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneE164: e164,
            verificationId: verificationId,
            country: _country,
          ),
        ),
      );
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
    if (msg.contains('invalid-phone-number')) {
      return AuthStrings.invalidPhoneNumber;
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
      appBar: AppBar(title: const Text(AuthStrings.signInWithPhone)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AuthStrings.phoneNumberLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _pickCountry,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_country.flagEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(_country.dialCode),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: AuthStrings.phoneNumberHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _sendCode,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(AuthStrings.sendCode),
            ),
          ],
        ),
      ),
    );
  }
}
