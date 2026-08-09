import 'package:equatable/equatable.dart';

class AuditLogEntry extends Equatable {
  final String id;
  final String actorId;
  final String action;
  final String? targetUserId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    this.targetUserId,
    this.metadata = const {},
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, actorId, action, targetUserId, createdAt];
}
