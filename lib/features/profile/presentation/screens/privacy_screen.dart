import 'package:flutter/material.dart';

/// Privacy screen structure only — same pattern as the top-level Settings
/// list before Account/Security were wired up. Each row here shows what's
/// coming; none of them are enforced yet (that needs RTDB rule changes
/// alongside the UI, so it's a dedicated later phase per section).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_PrivacyRow>[
      _PrivacyRow(
        'من يقدر يضيفني كجهة اتصال',
        Icons.person_add_alt_outlined,
        'الكل (افتراضي)',
      ),
      _PrivacyRow(
        'من يشوف حالة الاتصال (متصل الآن)',
        Icons.circle_outlined,
        'الكل (افتراضي)',
      ),
      _PrivacyRow(
        'من يقدر يتصل بي',
        Icons.call_outlined,
        'الكل (افتراضي)',
      ),
      _PrivacyRow(
        'المستخدمون المحظورون',
        Icons.block_outlined,
        'قسم منفصل',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الخصوصية')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = sections[index];
          return ListTile(
            leading: Icon(row.icon),
            title: Text(row.title),
            subtitle: Text(row.currentValue),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${row.title} — قريبًا')),
              );
            },
          );
        },
      ),
    );
  }
}

class _PrivacyRow {
  const _PrivacyRow(this.title, this.icon, this.currentValue);
  final String title;
  final IconData icon;
  final String currentValue;
}
