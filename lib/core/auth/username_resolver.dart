import 'package:firebase_database/firebase_database.dart';

/// Firebase Auth only understands email addresses, so when the user types
/// a username instead of an email on the login screen, we need to look up
/// the matching account's email first.
///
/// ASSUMPTION (please verify against your actual RTDB schema):
///   /users/{uid}/username  -> string, unique, lowercase
///   /users/{uid}/email     -> string
///
/// If your schema differs (e.g. a dedicated /usernames/{username}: uid
/// index), swap the query below accordingly — an indexed lookup table is
/// generally faster than the orderByChild scan used here once you have
/// many users.
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

    final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
    final firstUser = Map<String, dynamic>.from(usersMap.values.first as Map);
    return firstUser['email'] as String?;
  }

  /// Convenience helper: if [identifier] already looks like an email,
  /// returns it unchanged. Otherwise resolves it as a username.
  Future<String?> resolveIdentifierToEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return trimmed;
    return resolveEmail(trimmed);
  }
}
