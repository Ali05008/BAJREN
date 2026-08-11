import 'package:flutter/material.dart';

/// Settings screen structure only. Each section below is a real,
/// navigable entry in the list, but the destinations are not implemented
/// yet — this batch establishes the shape so later phases can fill in
/// each section without restructuring the entry point.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_SettingsSection>[
      _SettingsSection('الحساب', Icons.account_circle_outlined),
      _SettingsSection('الخصوصية', Icons.lock_outline),
      _SettingsSection('الأمان', Icons.security_outlined),
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
  const _SettingsSection(this.title, this.icon);
  final String title;
  final IconData icon;
}
