import 'dart:async';

import 'package:logger/logger.dart';

import '../../domain/services/call_engine.dart';
import '../../domain/services/signaling_service.dart';

/// Binds [SignalingService] to [CallEngine] for the lifetime of a user session.
///
/// - Forwards engine outbound messages → signaling.send
/// - Forwards signaling.incoming → engine.handleSignalingMessage
/// - Exposes [incomingOffers] for UI to show incoming call screen
class SignalingSession {
  SignalingSession({
    required SignalingService signaling,
    required CallEngine engine,
    Logger? logger,
  })  : _signaling = signaling,
        _engine = engine,
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final SignalingService _signaling;
  final CallEngine _engine;
  final Logger _log;

  final _offersCtrl = StreamController<SignalingMessage>.broadcast();
  StreamSubscription? _inSub;
  StreamSubscription? _outSub;

  /// Incoming offers while no active call handling yet (UI listens here).
  Stream<SignalingMessage> get incomingOffers => _offersCtrl.stream;

  Future<void> start(String userId) async {
    await stop();
    await _signaling.connect(userId);

    _outSub = _engine.outboundSignaling.listen((msg) async {
      try {
        // Fill from/to if engine left them empty
        final filled = SignalingMessage(
          callId: msg.callId,
          type: msg.type,
          payload: msg.payload,
          fromUserId: msg.fromUserId.isEmpty ? userId : msg.fromUserId,
          toUserId: msg.toUserId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        if (filled.toUserId.isEmpty) {
          _log.w('Dropping outbound ${filled.type.name} without toUserId');
          return;
        }
        await _signaling.send(filled);
      } catch (e, st) {
        _log.e('Failed to send signaling', error: e, stackTrace: st);
      }
    });

    _inSub = _signaling.incoming.listen((msg) async {
      try {
        if (msg.type == SignalingMessageType.offer) {
          _offersCtrl.add(msg);
        }
        await _engine.handleSignalingMessage(msg);
      } catch (e, st) {
        _log.e('Failed to handle signaling', error: e, stackTrace: st);
      }
    });

    _log.i('SignalingSession started for $userId');
  }

  Future<void> stop() async {
    await _inSub?.cancel();
    await _outSub?.cancel();
    _inSub = null;
    _outSub = null;
    await _signaling.disconnect();
  }

  Future<void> dispose() async {
    await stop();
    await _offersCtrl.close();
  }
}
