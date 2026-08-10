import 'package:shared_preferences/shared_preferences.dart';

/// Persists the email address an "email link" sign-in was sent to, so the
/// app can complete sign-in when the user opens the link later (possibly
/// after the app process was killed). Not sensitive data — no tokens or
/// codes are stored here, only the email address itself.
class PendingEmailLinkStore {
  static const _key = 'pending_email_link_address';

  Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, email.trim());
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
