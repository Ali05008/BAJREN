import 'package:equatable/equatable.dart';
import 'call.dart';

class CallConnectionState extends Equatable {
  final CallStatus status;
  final String? iceConnectionState;
  final String? iceGatheringState;
  final String? signalingState;
  final bool isReconnecting;
  final String? lastError;

  const CallConnectionState({
    required this.status,
    this.iceConnectionState,
    this.iceGatheringState,
    this.signalingState,
    this.isReconnecting = false,
    this.lastError,
  });

  const CallConnectionState.initial()
      : status = CallStatus.idle,
        iceConnectionState = null,
        iceGatheringState = null,
        signalingState = null,
        isReconnecting = false,
        lastError = null;

  CallConnectionState copyWith({
    CallStatus? status,
    String? iceConnectionState,
    String? iceGatheringState,
    String? signalingState,
    bool? isReconnecting,
    String? lastError,
  }) {
    return CallConnectionState(
      status: status ?? this.status,
      iceConnectionState: iceConnectionState ?? this.iceConnectionState,
      iceGatheringState: iceGatheringState ?? this.iceGatheringState,
      signalingState: signalingState ?? this.signalingState,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        iceConnectionState,
        iceGatheringState,
        signalingState,
        isReconnecting,
        lastError,
      ];
}
