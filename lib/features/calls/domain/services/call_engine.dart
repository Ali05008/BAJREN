import '../entities/call.dart';
import '../entities/call_media_state.dart';
import '../entities/call_connection_state.dart';
import '../entities/video_quality_level.dart';

/// Pure domain contract for the real-time calling engine.
/// No flutter_webrtc types leak into pure domain logic beyond MediaStream
/// which is accepted as a necessary rendering primitive.
abstract class CallEngine {
  Future<void> initialize();

  Future<void> startOutgoingCall(Call call);
  Future<void> acceptIncomingCall(Call call, {required Map<String, dynamic> remoteOffer});
  Future<void> rejectCall(String callId);
  Future<void> hangUp(String callId);

  // Media controls
  Future<void> toggleMute(bool muted);
  Future<void> toggleCamera(bool enabled);
  Future<void> switchCamera();
  Future<void> setSpeaker(bool enabled);

  // Adaptive quality
  Future<void> applyVideoQuality(String callId, VideoQualityLevel level);

  // Streams consumed by presentation
  Stream<CallMediaState> mediaStateStream(String callId);
  Stream<CallConnectionState> connectionStateStream(String callId);

  /// Signaling events that the upper layer (SignalingService) should forward.
  Stream<SignalingMessage> get outboundSignaling;

  /// Feed remote signaling messages into the engine.
  Future<void> handleSignalingMessage(SignalingMessage message);

  Future<void> dispose();
}

/// Simple signaling message DTO used between CallEngine and SignalingService.
class SignalingMessage {
  final String callId;
  final SignalingMessageType type;
  final Map<String, dynamic> payload;
  final String fromUserId;
  final String toUserId;
  final int timestamp;

  const SignalingMessage({
    required this.callId,
    required this.type,
    required this.payload,
    required this.fromUserId,
    required this.toUserId,
    int? timestamp,
  }) : timestamp = timestamp ?? 0;

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'type': type.name,
        'payload': payload,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'timestamp': timestamp == 0
            ? DateTime.now().millisecondsSinceEpoch
            : timestamp,
      };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'hangup';
    final type = SignalingMessageType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => SignalingMessageType.hangup,
    );
    return SignalingMessage(
      callId: json['callId'] as String? ?? '',
      type: type,
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? const {},
      ),
      fromUserId: json['fromUserId'] as String? ?? '',
      toUserId: json['toUserId'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}

enum SignalingMessageType {
  offer,
  answer,
  iceCandidate,
  hangup,
  reject,
  renegotiate,
}
