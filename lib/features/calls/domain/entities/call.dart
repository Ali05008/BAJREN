import 'package:equatable/equatable.dart';

enum CallType { voice, video }

enum CallStatus {
  idle,
  ringing,
  connecting,
  connected,
  reconnecting,
  ended,
  failed,
}

class Call extends Equatable {
  final String id;
  final CallType type;
  final String callerId;
  final String calleeId;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final Duration? duration;
  final String? failureReason;

  const Call({
    required this.id,
    required this.type,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.duration,
    this.failureReason,
  });

  Call copyWith({
    CallStatus? status,
    DateTime? answeredAt,
    DateTime? endedAt,
    Duration? duration,
    String? failureReason,
  }) {
    return Call(
      id: id,
      type: type,
      callerId: callerId,
      calleeId: calleeId,
      status: status ?? this.status,
      startedAt: startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        callerId,
        calleeId,
        status,
        startedAt,
        answeredAt,
        endedAt,
        duration,
        failureReason,
      ];
}
