import 'package:equatable/equatable.dart';

enum ReportStatus { open, inReview, closed }

/// Fixed set of reasons a user can pick when reporting another user.
/// Must stay in sync with REPORT_REASONS in functions/src/permissions.ts.
enum ReportReason {
  harassmentAbuse,
  inappropriateContent,
  impersonation,
  fraudScam,
  threats,
  other,
}

extension ReportReasonX on ReportReason {
  String get wireName {
    switch (this) {
      case ReportReason.harassmentAbuse:
        return 'HARASSMENT_ABUSE';
      case ReportReason.inappropriateContent:
        return 'INAPPROPRIATE_CONTENT';
      case ReportReason.impersonation:
        return 'IMPERSONATION';
      case ReportReason.fraudScam:
        return 'FRAUD_SCAM';
      case ReportReason.threats:
        return 'THREATS';
      case ReportReason.other:
        return 'OTHER';
    }
  }

  /// Arabic label shown in the report picker UI.
  String get label {
    switch (this) {
      case ReportReason.harassmentAbuse:
        return 'إساءة أو مضايقة';
      case ReportReason.inappropriateContent:
        return 'محتوى غير لائق';
      case ReportReason.impersonation:
        return 'انتحال شخصية';
      case ReportReason.fraudScam:
        return 'احتيال أو خداع';
      case ReportReason.threats:
        return 'تهديد';
      case ReportReason.other:
        return 'أخرى';
    }
  }

  static ReportReason? fromWire(String? value) {
    for (final r in ReportReason.values) {
      if (r.wireName == value) return r;
    }
    return null;
  }
}

class ModerationReport extends Equatable {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? reportedContentId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolverId;

  const ModerationReport({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.reportedContentId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolverId,
  });

  @override
  List<Object?> get props => [id, status, reporterId];
}
