import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../calls/presentation/providers/active_call_notifier.dart';
import '../../data/account_repository.dart';
import '../providers/account_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(accountProfileProvider);

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الحساب')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر تحميل بيانات الحساب')),
        data: (profile) {
          final displayName = profile?.displayName ?? user.displayName ?? 'مستخدم';
          final username = profile?.username;
          final email = profile?.email;

          return ListView(
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
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('الاسم الظاهر'),
                      subtitle: Text(displayName),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editDisplayName(
                        context,
                        ref,
                        uid: user.uid,
                        current: displayName,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: const Text('اسم المستخدم'),
                      subtitle: Text(username ?? '—'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editUsername(
                        context,
                        ref,
                        uid: user.uid,
                        current: username ?? '',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('البريد الإلكتروني'),
                      subtitle: Text(email ?? '—'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                  title: Text(
                    'حذف الحساب نهائيًا',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('يحذف حسابك وكل بياناتك بدون رجعة'),
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref, {
    required String uid,
    required String current,
  }) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم الظاهر'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'الاسم الظاهر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || !context.mounted) return;

    try {
      await ref.read(accountRepositoryProvider).updateDisplayName(
            uid: uid,
            displayName: result,
          );
    } on AccountException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editUsername(
    BuildContext context,
    WidgetRef ref, {
    required String uid,
    required String current,
  }) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم المستخدم'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اسم المستخدم'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || !context.mounted) return;

    try {
      await ref.read(accountRepositoryProvider).updateUsername(
            uid: uid,
            username: result,
          );
    } on AccountException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب نهائيًا؟'),
        content: const Text(
          'سيتم حذف حسابك وجهات اتصالك وكل بياناتك من كل الأقسام بشكل نهائي. '
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف نهائيًا'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(activeCallProvider.notifier).endCall();
      await ref.read(accountRepositoryProvider).deleteAccount();
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AccountException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حذف الحساب، حاول لاحقًا')),
        );
      }
    }
  }
}
