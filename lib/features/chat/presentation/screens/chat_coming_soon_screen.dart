import 'package:flutter/material.dart';

/// Placeholder for the Chat tab. Real-time messaging is a separate,
/// dedicated phase (Firebase-backed conversations, delivery/read state,
/// etc.) — this screen intentionally does not fake that functionality.
class ChatComingSoonScreen extends StatelessWidget {
  const ChatComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'المحادثات قادمة قريبًا',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'نعمل على بناء نظام محادثات لحظي متكامل.',
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
