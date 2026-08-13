import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// The signed-in user's editable profile fields.
///
/// [username] and [email] live under `/users/{uid}` (see
/// `UsernameResolver.saveBasicProfile`). [displayName] lives under
/// `/public_profiles/{uid}` (the same node the Contacts feature reads) and
/// is mirrored onto the Firebase Auth user record so it shows up anywhere
/// Firebase Auth's own `displayName` is used.
class AccountProfile {
  final String uid;
  final String? username;
  final String? email;
  final String? displayName;

  const AccountProfile({
    required this.uid,
    this.username,
    this.email,
    this.displayName,
  });
}

class AccountException implements Exception {
  final String code;
  final String message;

  const AccountException(this.code, this.message);

  @override
  String toString() => 'AccountException($code): $message';
}

class AccountRepository {
  AccountRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  DatabaseReference _userRef(String uid) => _db.ref('users/$uid');
  DatabaseReference _publicProfileRef(String uid) =>
      _db.ref('public_profiles/$uid');

  /// Live view of the signed-in user's profile fields, combining
  /// `/users/{uid}` (username, email) and `/public_profiles/{uid}`
  /// (displayName).
  Stream<AccountProfile> watchProfile(String uid) {
    final userStream = _userRef(uid).onValue;
    final publicStream = _publicProfileRef(uid).onValue;

    String? username;
    String? email;
    String? displayName;

    late final StreamController<AccountProfile> controller;
    controller = StreamController<AccountProfile>.broadcast(
      onListen: () {},
    );

    void emit() {
      controller.add(
        AccountProfile(
          uid: uid,
          username: username,
          email: email,
          displayName: displayName,
        ),
      );
    }

    final subs = <StreamSubscription>[];
    subs.add(userStream.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        username = data['username'] as String?;
        email = data['email'] as String?;
      }
      emit();
    }));
    subs.add(publicStream.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        displayName = data['displayName'] as String?;
      }
      emit();
    }));

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  /// Checks whether [username] is free to take. [currentUid] is excluded
  /// from the check so a user can "change" their own username to itself
  /// (e.g. only editing letter case) without tripping the duplicate check.
  Future<bool> isUsernameAvailable({
    required String username,
    required String currentUid,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final query = _db
        .ref('users')
        .orderByChild('username')
        .equalTo(normalized)
        .limitToFirst(2);

    final snapshot = await query.get();
    if (!snapshot.exists) return true;

    final matches = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final otherUids = matches.keys.where((k) => k != currentUid);
    return otherUids.isEmpty;
  }

  /// Updates the username shown under `/users/{uid}`. Throws
  /// [AccountException] with code `taken` if another account already uses
  /// it.
  Future<void> updateUsername({
    required String uid,
    required String username,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const AccountException('invalid', 'اسم المستخدم لا يمكن أن يكون فارغًا');
    }

    final available = await isUsernameAvailable(
      username: normalized,
      currentUid: uid,
    );
    if (!available) {
      throw const AccountException('taken', 'اسم المستخدم هذا مستخدم بالفعل');
    }

    await _userRef(uid).update({'username': normalized});
  }

  /// Updates the display name shown across the app (Contacts, Profile,
  /// etc.) and mirrors it onto the Firebase Auth user record.
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const AccountException('invalid', 'الاسم لا يمكن أن يكون فارغًا');
    }

    await _auth.currentUser?.updateDisplayName(trimmed);
    await _publicProfileRef(uid).update({'displayName': trimmed});
  }

  /// Permanently deletes the signed-in user's account: Firebase Auth
  /// record, RTDB profile/contacts/signaling data, and any admin role
  /// grant. Runs server-side via the `deleteMyAccount` Cloud Function so
  /// it works even though RTDB rules don't let the client delete other
  /// users' reverse-contact entries directly.
  ///
  /// The caller is responsible for signing the local session out
  /// afterwards (the server deleting the Auth user does not immediately
  /// invalidate the client's cached session).
  Future<void> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteMyAccount').call<dynamic>();
    } on FirebaseFunctionsException catch (e) {
      throw AccountException(
        e.code,
        e.message ?? 'تعذر حذف الحساب، حاول لاحقًا',
      );
    }
  }
}
