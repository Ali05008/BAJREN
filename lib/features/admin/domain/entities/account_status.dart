enum AccountStatus {
  /// Normal access.
  active,
  /// User or admin disabled; cannot sign in / use services.
  disabled,
  /// Temporary block until [suspendedUntil].
  suspended,
  /// Permanent ban; requires explicit unban.
  banned,
  /// Soft-deleted / scheduled for purge.
  deleted,
}

extension AccountStatusX on AccountStatus {
  String get wireName {
    switch (this) {
      case AccountStatus.active:
        return 'ACTIVE';
      case AccountStatus.disabled:
        return 'DISABLED';
      case AccountStatus.suspended:
        return 'SUSPENDED';
      case AccountStatus.banned:
        return 'BANNED';
      case AccountStatus.deleted:
        return 'DELETED';
    }
  }

  static AccountStatus fromWire(String? v) {
    switch ((v ?? 'ACTIVE').toUpperCase()) {
      case 'DISABLED':
        return AccountStatus.disabled;
      case 'SUSPENDED':
        return AccountStatus.suspended;
      case 'BANNED':
        return AccountStatus.banned;
      case 'DELETED':
        return AccountStatus.deleted;
      default:
        return AccountStatus.active;
    }
  }
}
