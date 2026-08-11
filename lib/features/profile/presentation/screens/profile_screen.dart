import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../calls/presentation/providers/active_call_notifier.dart';
import 'settings_placeholder_screen.dart';

/// Profile tab. This batch builds the navigable structure only — full
/// editing, avatar upload, bio, blocked users, etc. are dedicated later
/// batches. What IS real here: reading the signed-in user and signing out,
/// both wired to the existing Firebase Auth repository.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'مستخدم',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.uid,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('الإعدادات'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsPlaceholderScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade400),
                  title: Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  onTap: () async {
                    await ref.read(activeCallProvider.notifier).endCall();
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
