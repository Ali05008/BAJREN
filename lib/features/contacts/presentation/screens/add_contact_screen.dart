import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/contacts_repository.dart';
import '../providers/contacts_providers.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _uidController = TextEditingController();

  bool _loading = false;
  String? _error;
  ContactLookupResult? _found;

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final input = _uidController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _found = null;
    });

    final me = ref.read(currentUserProvider);
    final isEmail = input.contains('@');

    String? uid = input;
    if (isEmail) {
      uid = await ref
          .read(emailIndexServiceProvider)
          .resolveUidByEmail(input);
      if (uid == null) {
        setState(() {
          _loading = false;
          _error = 'لا يوجد مستخدم مسجّل بهذا البريد الإلكتروني.';
        });
        return;
      }
    }

    if (me != null && uid == me.uid) {
      setState(() {
        _loading = false;
        _error = 'لا يمكنك إضافة نفسك كجهة اتصال.';
      });
      return;
    }

    try {
      final result =
          await ref.read(contactsRepositoryProvider).lookupUserByUid(uid);

      setState(() {
        _loading = false;

        if (result == null) {
          _error = 'لا يوجد مستخدم بهذا المعرف.';
        } else {
          _found = result;
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'حدث خطأ ما، حاول مرة أخرى.';
      });
    }
  }

  Future<void> _addContact() async {
    final found = _found;
    final me = ref.read(currentUserProvider);

    if (found == null || me == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(contactsRepositoryProvider).addContact(
            ownerUid: me.uid,
            contactUid: found.uid,
            contactDisplayName: found.displayName,
            ownerDisplayName: me.displayName ?? me.uid,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة ${found.displayName} إلى جهات الاتصال.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } on ContactException catch (e) {
      setState(() {
        _loading = false;

        switch (e.code) {
          case 'self-add':
            _error = 'لا يمكنك إضافة نفسك كجهة اتصال.';
            break;
          case 'duplicate':
            _error = 'تمت إضافة جهة الاتصال هذه من قبل.';
            break;
          case 'privacy-blocked':
            _error = 'هذا المستخدم لا يسمح بإضافته كجهة اتصال.';
            break;
          default:
            _error = 'تعذّرت إضافة جهة الاتصال، حاول مرة أخرى.';
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'حدث خطأ ما، حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة جهة اتصال'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل البريد الإلكتروني للشخص الذي تريد إضافته (أو معرف المستخدم UID).',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uidController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني أو UID',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('بحث'),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_found != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      _found!.displayName.isNotEmpty
                          ? _found!.displayName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(_found!.displayName),
                  subtitle: Text(_found!.uid),
                  trailing: FilledButton(
                    onPressed: _loading ? null : _addContact,
                    child: const Text('إضافة'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
