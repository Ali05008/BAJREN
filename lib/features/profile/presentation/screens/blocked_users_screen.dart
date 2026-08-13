import 'package:flutter/material.dart';

/// Blocked Users screen structure only. Shows the empty state a real
/// blocked-list would have; there's no blocking data model yet (that
/// needs a `blocked/{uid}/{blockedUid}` RTDB node plus rule changes so
/// blocked users can't message/call/add each other) so this doesn't wire
/// to anything real yet.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون المحظورون')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'ما فيه مستخدمون محظورون',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'المستخدمون اللي تحظرهم بيظهرون هنا. هذه الميزة قادمة قريبًا.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
