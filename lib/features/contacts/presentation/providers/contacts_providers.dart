import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/firebase_contacts_repository.dart';
import '../../domain/contact.dart';
import '../../domain/contacts_repository.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return FirebaseContactsRepository();
});

final contactsListProvider = StreamProvider<List<Contact>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.watchContacts(user.uid);
});

final publicProfileSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final repo = ref.watch(contactsRepositoryProvider);

  await repo.ensureOwnPublicProfile(
    uid: user.uid,
    displayName: user.displayName ?? user.uid,
  );
});
