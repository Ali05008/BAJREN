import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'security_screen.dart';

/// Settings screen structure. Each section below is a real, navigable
/// entry in the list. Sections that have a real destination navigate
/// there; the rest still show "قريبًا" until their own phase lands.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_SettingsSection>[
      _SettingsSection(
        'الحساب',
        Icons.account_circle_outlined,
        builder: (_) => const AccountScreen(),
      ),
      _SettingsSection('الخصوصية', Icons.lock_outline),
      _SettingsSection(
        'الأمان',
        Icons.security_outlined,
        builder: (_) => const SecurityScreen(),
      ),
      _SettingsSection('الإشعارات', Icons.notifications_outlined),
      _SettingsSection('المستخدمون المحظورون', Icons.block_outlined),
      _SettingsSection('عام', Icons.tune_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final section = sections[index];
          return ListTile(
            leading: Icon(section.icon),
            title: Text(section.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (section.builder != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: section.builder!),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${section.title} — قريبًا')),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsSection {
  const _SettingsSection(this.title, this.icon, {this.builder});
  final String title;
  final IconData icon;
  final WidgetBuilder? builder;
}
