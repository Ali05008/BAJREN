import 'package:firebase_database/firebase_database.dart';

/// Firebase Auth (and therefore [AuthRepository.signInWithEmail]) only
/// understands email addresses. This resolver lets the login screen
/// accept either an email OR a username by looking the username up in
/// Realtime Database first.
///
/// ASSUMPTION (please confirm/adjust against your actual schema once the
/// Profile phase writes user records):
///   /users/{uid}/username  -> string, unique, stored lowercase
///   /users/{uid}/email     -> string
///
/// If your schema uses a dedicated index instead (e.g.
/// /usernames/{username}: uid), swap resolveEmail() below to read that
/// path directly — it'll be faster than the orderByChild scan used here
/// once you have a large user base.
class UsernameResolver {
  UsernameResolver({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  /// Returns the email address associated with [username], or null if no
  /// matching account was found.
  Future<String?> resolveEmail(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final query = _db
        .ref('users')
        .orderByChild('username')
        .equalTo(normalized)
        .limitToFirst(1);

    final snapshot = await query.get();
    if (!snapshot.exists) return null;

    final usersMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final firstUser = Map<dynamic, dynamic>.from(usersMap.values.first as Map);
    return firstUser['email'] as String?;
  }

  /// If [identifier] already looks like an email, returns it unchanged.
  /// Otherwise resolves it as a username via Realtime Database.
  Future<String?> resolveIdentifierToEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return trimmed;
    return resolveEmail(trimmed);
  }

  /// Lightweight placeholder profile write so freshly-registered accounts
  /// are immediately findable by username on their very next sign-in.
  /// This intentionally only writes {username, email} — the full profile
  /// (display name, bio, avatar, verification level, etc.) belongs to the
  /// Profile phase and should extend/replace this record then.
  Future<void> saveBasicProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    await _db.ref('users/$uid').update({
      'username': username.trim().toLowerCase(),
      'email': email.trim(),
    });
  }
}
