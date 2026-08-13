import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shows read-only info about the current session: when the account was
/// created, when it last signed in, which sign-in method is linked, and
/// which device/OS this session is running on. No session-management
/// actions yet (e.g. remote sign-out) — that needs a device/session
/// registry this project doesn't have, and is a later phase.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الأمان')),
      body: user == null
          ? const Center(child: Text('لا توجد جلسة نشطة'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.login_outlined),
                        title: const Text('آخر تسجيل دخول'),
                        subtitle: Text(_formatDate(user.metadata.lastSignInTime)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: const Text('تاريخ إنشاء الحساب'),
                        subtitle: Text(_formatDate(user.metadata.creationTime)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('طريقة تسجيل الدخول'),
                        subtitle: Text(_signInMethodLabel(user)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_android_outlined),
                        title: const Text('الجهاز الحالي'),
                        subtitle: Text(_deviceLabel()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'إدارة الجلسات من أجهزة أخرى قادمة لاحقًا.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _signInMethodLabel(User user) {
    if (user.providerData.isEmpty) {
      // Email Link and some anonymous/custom flows don't populate
      // providerData with a distinct provider beyond the base account.
      return user.email != null ? 'رابط تسجيل الدخول عبر البريد' : 'دخول مجهول';
    }
    final ids = user.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('google.com')) return 'جوجل';
    if (ids.contains('password')) {
      return user.email != null ? 'البريد الإلكتروني' : 'البريد وكلمة المرور';
    }
    if (ids.contains('phone')) return 'رقم الجوال';
    return ids.first;
  }

  String _deviceLabel() {
    try {
      if (Platform.isAndroid) return 'Android ${Platform.operatingSystemVersion}';
      if (Platform.isIOS) return 'iOS ${Platform.operatingSystemVersion}';
      return Platform.operatingSystem;
    } catch (_) {
      return '—';
    }
  }
}
