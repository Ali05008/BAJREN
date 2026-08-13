import 'package:equatable/equatable.dart';

import 'contact.dart';

class ContactLookupResult extends Equatable {
  final String uid;
  final String displayName;

  const ContactLookupResult({
    required this.uid,
    required this.displayName,
  });

  @override
  List<Object?> get props => [uid, displayName];
}

abstract class ContactsRepository {
  Stream<List<Contact>> watchContacts(String ownerUid);

  Future<void> ensureOwnPublicProfile({
    required String uid,
    required String displayName,
  });

  Future<ContactLookupResult?> lookupUserByUid(String uid);

  /// Throws [ContactException] with code 'self-add', 'duplicate', or
  /// 'privacy-blocked' (target set "من يقدر يضيفني كجهة اتصال" to "لا أحد").
  Future<void> addContact({
    required String ownerUid,
    required String contactUid,
    required String contactDisplayName,
    required String ownerDisplayName,
  });

  Future<void> removeContact({
    required String ownerUid,
    required String contactUid,
  });
}

class ContactException implements Exception {
  final String code;
  final String message;

  const ContactException(this.code, this.message);

  @override
  String toString() => 'ContactException($code): $message';
}
