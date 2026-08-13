import 'package:firebase_database/firebase_database.dart';

import '../domain/privacy_repository.dart';

class FirebasePrivacyRepository implements PrivacyRepository {
  FirebasePrivacyRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference _allowContactByRef(String uid) =>
      _db.ref('privacy/$uid/allowContactBy');

  @override
  Stream<ContactPermission> watchAllowContactBy(String uid) {
    return _allowContactByRef(uid).onValue.map((event) {
      return ContactPermission.fromWire(event.snapshot.value);
    });
  }

  @override
  Future<void> setAllowContactBy(String uid, ContactPermission value) async {
    await _allowContactByRef(uid).set(value.wireValue);
  }

  @override
  Future<ContactPermission> getAllowContactBy(String uid) async {
    final snapshot = await _allowContactByRef(uid).get();
    return ContactPermission.fromWire(snapshot.value);
  }
}
