import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallMediaState extends Equatable {
  final bool isMuted;
  final bool isCameraOn;
  final bool isFrontCamera;
  final bool isSpeakerOn;
  final bool isBluetoothOn;
  final MediaStream? localStream;
  final MediaStream? remoteStream;

  const CallMediaState({
    this.isMuted = false,
    this.isCameraOn = true,
    this.isFrontCamera = true,
    this.isSpeakerOn = false,
    this.isBluetoothOn = false,
    this.localStream,
    this.remoteStream,
  });

  const CallMediaState.initial()
      : isMuted = false,
        isCameraOn = true,
        isFrontCamera = true,
        isSpeakerOn = false,
        isBluetoothOn = false,
        localStream = null,
        remoteStream = null;

  CallMediaState copyWith({
    bool? isMuted,
    bool? isCameraOn,
    bool? isFrontCamera,
    bool? isSpeakerOn,
    bool? isBluetoothOn,
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool clearLocalStream = false,
    bool clearRemoteStream = false,
  }) {
    return CallMediaState(
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      localStream: clearLocalStream ? null : (localStream ?? this.localStream),
      remoteStream:
          clearRemoteStream ? null : (remoteStream ?? this.remoteStream),
    );
  }

  @override
  List<Object?> get props => [
        isMuted,
        isCameraOn,
        isFrontCamera,
        isSpeakerOn,
        isBluetoothOn,
        localStream?.id,
        remoteStream?.id,
      ];
}
