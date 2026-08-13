import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../calls/domain/entities/call.dart';
import '../../../calls/presentation/providers/active_call_notifier.dart';
import '../../../calls/presentation/screens/home_screen.dart';
import '../../../chat/presentation/screens/conversation_screen.dart';
import '../../domain/contact.dart';
import '../providers/contacts_providers.dart';
import '../widgets/verified_badge.dart';
import 'add_contact_screen.dart';

class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(publicProfileSyncProvider);
    ref.watch(emailIndexSyncProvider);

    final contactsAsync = ref.watch(contactsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات الاتصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'إضافة جهة اتصال',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddContactScreen(),
              ),
            ),
          ),
        ],
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد جهات اتصال حتى الآن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أضف جهة اتصال باستخدام معرف المستخدم (UID) للبدء.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddContactScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('إضافة جهة اتصال'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isVerifiedAsync = ref.watch(isVerifiedProvider(contact.uid));
              final isVerified = isVerifiedAsync.asData?.value ?? false;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(contact.displayName)),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(),
                    ],
                  ],
                ),
                subtitle: Text(contact.uid),
                onTap: () => _showContactSheet(
                  context,
                  ref,
                  contact,
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('حدث خطأ: $e'),
        ),
      ),
    );
  }

  void _startCall(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
    CallType type,
  ) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;

    ref.read(activeCallProvider.notifier).startOutgoingCall(
          callerId: me.uid,
          calleeId: contact.uid,
          type: type,
        );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showContactSheet(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(contact.displayName),
              subtitle: Text(contact.uid),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('إرسال رسالة'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      otherUid: contact.uid,
                      otherDisplayName: contact.displayName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('مكالمة صوتية'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _startCall(context, ref, contact, CallType.voice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('مكالمة فيديو'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _startCall(context, ref, contact, CallType.video);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'حذف جهة الاتصال',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();

                final owner = ref.read(currentUserProvider);
                if (owner == null) return;

                await ref
                    .read(contactsRepositoryProvider)
                    .removeContact(
                      ownerUid: owner.uid,
                      contactUid: contact.uid,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف جهة الاتصال.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
