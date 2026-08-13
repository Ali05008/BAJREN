import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Looks up a user's Firebase UID by their sign-in email address, so
/// people can add a contact or start a call by typing an email (like
/// Google Meet) instead of sharing a raw UID.
///
/// Backed by `/email_index/{sanitizedEmail} -> uid` in Realtime Database.
/// Only the UID is stored (no other personal data), and RTDB rules only
/// let a signed-in user write the entry matching their own verified
/// sign-in email (`auth.token.email`), so nobody can point another
/// person's email at their own account.
class EmailIndexService {
  EmailIndexService({FirebaseDatabase? database, FirebaseAuth? auth})
      : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  /// RTDB keys can't contain '.', so dots are swapped for ','. Must stay
  /// in sync with the equivalent logic in
  /// `docs/firebase_database.rules.json`.
  static String keyFor(String email) =>
      email.trim().toLowerCase().replaceAll('.', ',');

  /// Writes/refreshes the signed-in user's own email -> uid mapping.
  /// Safe to call on every app start; a no-op write if unchanged. Silently
  /// does nothing if there's no signed-in user or no email on the account
  /// (e.g. phone-only auth).
  Future<void> syncCurrentUser() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) return;

    await _db.ref('email_index/${keyFor(email)}').set(user.uid);
  }

  /// Returns the uid registered under [email], or null if no account has
  /// claimed that email yet.
  Future<String?> resolveUidByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    final snapshot = await _db.ref('email_index/${keyFor(trimmed)}').get();
    if (!snapshot.exists) return null;
    final value = snapshot.value;
    return value is String ? value : null;
  }
}
