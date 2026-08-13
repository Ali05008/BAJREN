import 'package:flutter/material.dart';

/// Notifications screen structure only — same pattern as Privacy. Rows
/// describe what's coming; none control real FCM behavior yet. Wiring
/// these to actually suppress/allow push notifications needs a per-user
/// preferences node read by the sending Cloud Functions, which is a
/// dedicated later phase.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_NotificationRow>[
      _NotificationRow(
        'إشعارات المكالمات',
        Icons.call_outlined,
        'مفعّل (افتراضي)',
      ),
      _NotificationRow(
        'إشعارات الرسائل',
        Icons.chat_bubble_outline,
        'مفعّل (افتراضي)',
      ),
      _NotificationRow(
        'إشعارات جهات الاتصال الجديدة',
        Icons.person_add_alt_outlined,
        'مفعّل (افتراضي)',
      ),
      _NotificationRow(
        'الصوت والاهتزاز',
        Icons.vibration_outlined,
        'افتراضي النظام',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
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

class _NotificationRow {
  const _NotificationRow(this.title, this.icon, this.currentValue);
  final String title;
  final IconData icon;
  final String currentValue;
}
