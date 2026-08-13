import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/email_index_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/firebase_contacts_repository.dart';
import '../../domain/contact.dart';
import '../../domain/contacts_repository.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return FirebaseContactsRepository();
});

final emailIndexServiceProvider = Provider<EmailIndexService>((ref) {
  return EmailIndexService();
});

/// Keeps `/email_index` in sync with the signed-in user's sign-in email so
/// others can find them by email (Contacts "add by email" and Calls
/// "call by email"). Watched once from an always-mounted tab
/// (ContactsListScreen) alongside [publicProfileSyncProvider].
final emailIndexSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  await ref.watch(emailIndexServiceProvider).syncCurrentUser();
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

/// Streams whether a given uid's public profile is verified. Used to show
/// the checkmark badge in Contacts and Chat without touching the base
/// Contact stream (public_profiles/isVerified is only ever written by
/// the adminSetVerified Cloud Function).
final isVerifiedProvider =
    StreamProvider.family<bool, String>((ref, uid) {
  return FirebaseDatabase.instance
      .ref('public_profiles/$uid/isVerified')
      .onValue
      .map((event) => event.snapshot.value == true);
});
