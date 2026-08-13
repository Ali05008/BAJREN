/// Who is allowed to add the current user as a contact.
enum ContactPermission {
  everyone,
  nobody;

  String get wireValue => switch (this) {
        ContactPermission.everyone => 'all',
        ContactPermission.nobody => 'nobody',
      };

  static ContactPermission fromWire(Object? value) {
    if (value == 'nobody') return ContactPermission.nobody;
    return ContactPermission.everyone;
  }
}

abstract class PrivacyRepository {
  /// Streams the current user's own contact-permission setting.
  Stream<ContactPermission> watchAllowContactBy(String uid);

  Future<void> setAllowContactBy(String uid, ContactPermission value);

  /// Reads another user's contact-permission setting once, used before
  /// attempting to add them as a contact so the UI can show a clear
  /// message instead of a generic RTDB permission-denied error.
  Future<ContactPermission> getAllowContactBy(String uid);
}
