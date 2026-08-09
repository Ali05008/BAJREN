import 'dart:async';

import '../../domain/services/call_engine.dart';
import '../../domain/services/signaling_service.dart';

/// Simple in-memory signaling for local testing / unit tests.
/// Replace with Firebase / Supabase / WebSocket implementation in production.
class InMemorySignalingService implements SignalingService {
  final _controller = StreamController<SignalingMessage>.broadcast();
  String? _userId;
  bool _connected = false;

  // Static bus so two instances in the same process can talk (useful for tests).
  static final _globalBus = StreamController<SignalingMessage>.broadcast();

  @override
  bool get isConnected => _connected;

  @override
  Stream<SignalingMessage> get incoming => _controller.stream;

  @override
  Future<void> connect(String userId) async {
    _userId = userId;
    _connected = true;
    // Forward messages addressed to this user.
    _globalBus.stream.listen((msg) {
      if (msg.toUserId == _userId) {
        _controller.add(msg);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _userId = null;
  }

  @override
  Future<void> send(SignalingMessage message) async {
    if (!_connected) {
      throw StateError('SignalingService is not connected');
    }
    _globalBus.add(message);
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
