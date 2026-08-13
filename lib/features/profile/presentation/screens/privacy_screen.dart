import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/privacy_repository.dart';
import '../providers/privacy_providers.dart';

/// Privacy screen. "من يقدر يضيفني كجهة اتصال" is wired to real RTDB
/// data via [allowContactByProvider] + [PrivacyRepository]; the rest are
/// still scaffolding until their own phase lands.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allowContactByAsync = ref.watch(allowContactByProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الخصوصية')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          allowContactByAsync.when(
            data: (value) => ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: const Text('من يقدر يضيفني كجهة اتصال'),
              subtitle: Text(
                value == ContactPermission.nobody
                    ? 'لا أحد'
                    : 'الكل',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: user == null
                  ? null
                  : () => _showContactPermissionSheet(
                        context,
                        ref,
                        user.uid,
                        value,
                      ),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.person_add_alt_outlined),
              title: Text('من يقدر يضيفني كجهة اتصال'),
              trailing: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: const Text('من يقدر يضيفني كجهة اتصال'),
              subtitle: const Text('تعذّر التحميل'),
              onTap: user == null
                  ? null
                  : () => _showContactPermissionSheet(
                        context,
                        ref,
                        user.uid,
                        ContactPermission.everyone,
                      ),
            ),
          ),
          const Divider(height: 1),
          const _PlaceholderRow(
            title: 'من يشوف حالة الاتصال (متصل الآن)',
            icon: Icons.circle_outlined,
            currentValue: 'الكل (افتراضي)',
          ),
          const Divider(height: 1),
          const _PlaceholderRow(
            title: 'من يقدر يتصل بي',
            icon: Icons.call_outlined,
            currentValue: 'الكل (افتراضي)',
          ),
          const Divider(height: 1),
          const _PlaceholderRow(
            title: 'المستخدمون المحظورون',
            icon: Icons.block_outlined,
            currentValue: 'قسم منفصل',
          ),
        ],
      ),
    );
  }

  void _showContactPermissionSheet(
    BuildContext context,
    WidgetRef ref,
    String uid,
    ContactPermission current,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'من يقدر يضيفني كجهة اتصال',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            RadioListTile<ContactPermission>(
              value: ContactPermission.everyone,
              groupValue: current,
              title: const Text('الكل'),
              onChanged: (value) => _apply(sheetContext, ref, uid, value),
            ),
            RadioListTile<ContactPermission>(
              value: ContactPermission.nobody,
              groupValue: current,
              title: const Text('لا أحد'),
              onChanged: (value) => _apply(sheetContext, ref, uid, value),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(
    BuildContext sheetContext,
    WidgetRef ref,
    String uid,
    ContactPermission? value,
  ) async {
    if (value == null) return;
    Navigator.of(sheetContext).pop();
    await ref.read(privacyRepositoryProvider).setAllowContactBy(uid, value);
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({
    required this.title,
    required this.icon,
    required this.currentValue,
  });

  final String title;
  final IconData icon;
  final String currentValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(currentValue),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — قريبًا')),
        );
      },
    );
  }
}
