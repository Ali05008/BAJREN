import 'call_engine.dart';

/// Abstraction for the signaling transport.
/// Implementations can use Firebase Realtime, Firestore, Supabase Realtime,
/// or a custom WebSocket server.
abstract class SignalingService {
  /// Start listening for signaling messages addressed to [userId].
  Future<void> connect(String userId);

  /// Stop listening and clean up.
  Future<void> disconnect();

  /// Send a signaling message to the remote peer.
  Future<void> send(SignalingMessage message);

  /// Stream of incoming signaling messages for the connected user.
  Stream<SignalingMessage> get incoming;

  /// Whether the transport is currently connected.
  bool get isConnected;
}
