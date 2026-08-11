import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../domain/contact.dart';
import '../domain/contacts_repository.dart';

class FirebaseContactsRepository implements ContactsRepository {
  FirebaseContactsRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference get _contactsRoot => _db.ref('contacts');

  DatabaseReference get _publicProfilesRoot =>
      _db.ref('public_profiles');

  @override
  Stream<List<Contact>> watchContacts(String ownerUid) {
    return _contactsRoot.child(ownerUid).onValue.map((event) {
      final data = event.snapshot.value;

      if (data is! Map) {
        return <Contact>[];
      }

      final contacts = <Contact>[];

      data.forEach((key, value) {
        if (value is! Map) return;

        final addedAtRaw = value['addedAt'];

        final addedAtMs = addedAtRaw is int
            ? addedAtRaw
            : (addedAtRaw is double ? addedAtRaw.toInt() : null);

        final displayName = value['displayName'];

        if (addedAtMs == null || displayName is! String) {
          return;
        }

        contacts.add(
          Contact(
            uid: key.toString(),
            displayName: displayName,
            addedAt: DateTime.fromMillisecondsSinceEpoch(
              addedAtMs,
            ),
          ),
        );
      });

      contacts.sort(
        (a, b) => b.addedAt.compareTo(a.addedAt),
      );

      return contacts;
    });
  }

  @override
  Future<void> ensureOwnPublicProfile({
    required String uid,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();

    if (trimmed.isEmpty) return;

    await _publicProfilesRoot.child(uid).update({
      'displayName': trimmed,
    });
  }

  @override
  Future<ContactLookupResult?> lookupUserByUid(
    String uid,
  ) async {
    final trimmed = uid.trim();

    if (trimmed.isEmpty) return null;

    final snapshot =
        await _publicProfilesRoot.child(trimmed).get();

    if (!snapshot.exists) return null;

    final data = snapshot.value;

    if (data is! Map) return null;

    final displayName = data['displayName'];

    if (displayName is! String || displayName.isEmpty) {
      return null;
    }

    return ContactLookupResult(
      uid: trimmed,
      displayName: displayName,
    );
  }

  @override
  Future<void> addContact({
    required String ownerUid,
    required String contactUid,
    required String contactDisplayName,
    required String ownerDisplayName,
  }) async {
    if (ownerUid == contactUid) {
      throw const ContactException(
        'self-add',
        'You cannot add yourself as a contact.',
      );
    }

    final existing = await _contactsRoot
        .child(ownerUid)
        .child(contactUid)
        .get();

    if (existing.exists) {
      throw const ContactException(
        'duplicate',
        'This contact has already been added.',
      );
    }

    final now = ServerValue.timestamp;

    final updates = <String, dynamic>{
      'contacts/$ownerUid/$contactUid': {
        'displayName': contactDisplayName,
        'addedAt': now,
      },
      'contacts/$contactUid/$ownerUid': {
        'displayName': ownerDisplayName,
        'addedAt': now,
      },
    };

    try {
      await _db.ref().update(updates);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ContactException(
          'duplicate',
          'This contact has already been added.',
        );
      }

      rethrow;
    }
  }

  @override
  Future<void> removeContact({
    required String ownerUid,
    required String contactUid,
  }) async {
    final updates = <String, dynamic>{
      'contacts/$ownerUid/$contactUid': null,
      'contacts/$contactUid/$ownerUid': null,
    };

    await _db.ref().update(updates);
  }
}
