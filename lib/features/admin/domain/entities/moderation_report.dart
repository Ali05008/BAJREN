import 'package:equatable/equatable.dart';

enum ReportStatus { open, inReview, closed }

class ModerationReport extends Equatable {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? reportedContentId;
  final String reason;
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
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolverId,
  });

  @override
  List<Object?> get props => [id, status, reporterId];
}
