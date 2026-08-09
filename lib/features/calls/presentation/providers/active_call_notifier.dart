import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/active_call_state.dart';
import '../../domain/entities/call.dart';
import '../../domain/entities/call_media_state.dart';
import '../../domain/entities/call_connection_state.dart';
import '../../domain/entities/video_quality_level.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/services/call_engine.dart';
import 'call_providers.dart';

class ActiveCallNotifier extends AsyncNotifier<ActiveCallState?> {
  CallEngine get _engine => ref.read(callEngineProvider);
  CallRepository get _repository => ref.read(callRepositoryProvider);

  String? _currentCallId;
  StreamSubscription? _mediaSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _callSub;
  StreamSubscription? _signalingSub;

  @override
  FutureOr<ActiveCallState?> build() {
    ref.onDispose(_cancelSubscriptions);
    return null;
  }

  Future<void> startOutgoingCall({
    required String callerId,
    required String calleeId,
    required CallType type,
  }) async {
    state = const AsyncLoading();
    try {
      final call = await _repository.startCall(
        callerId: callerId,
        calleeId: calleeId,
        type: type,
      );
      _currentCallId = call.id;
      await _engine.startOutgoingCall(call);
      _listen(call.id);

      state = AsyncData(ActiveCallState(
        call: call,
        media: const CallMediaState.initial(),
        connection: const CallConnectionState(status: CallStatus.connecting),
        currentQuality: VideoQualityLevel.high,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> acceptIncomingCall(
    Call call, {
    required Map<String, dynamic> remoteOffer,
  }) async {
    state = const AsyncLoading();
    try {
      _currentCallId = call.id;
      await _repository.answerCall(call.id);
      await _engine.acceptIncomingCall(call, remoteOffer: remoteOffer);
      _listen(call.id);

      state = AsyncData(ActiveCallState(
        call: call,
        media: const CallMediaState.initial(),
        connection: const CallConnectionState(status: CallStatus.connecting),
        currentQuality: VideoQualityLevel.high,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> endCall() async {
    final id = _currentCallId;
    if (id == null) return;
    try {
      await _engine.hangUp(id);
      await _repository.endCall(id);
    } finally {
      _cancelSubscriptions();
      _currentCallId = null;
      state = const AsyncData(null);
    }
  }

  Future<void> toggleMute() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final muted = !cur.media.isMuted;
    await _engine.toggleMute(muted);
    state = AsyncData(cur.copyWith(
      media: cur.media.copyWith(isMuted: muted),
    ));
  }

  Future<void> toggleCamera() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final on = !cur.media.isCameraOn;
    await _engine.toggleCamera(on);
    state = AsyncData(cur.copyWith(
      media: cur.media.copyWith(isCameraOn: on),
    ));
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> setSpeaker(bool enabled) async {
    await _engine.setSpeaker(enabled);
  }

  void _listen(String callId) {
    _cancelSubscriptions();

    _mediaSub = _engine.mediaStateStream(callId).listen((media) {
      final cur = state.valueOrNull;
      if (cur == null) return;
      state = AsyncData(cur.copyWith(media: media));
    });

    _connectionSub = _engine.connectionStateStream(callId).listen((conn) {
      final cur = state.valueOrNull;
      if (cur == null) return;
      state = AsyncData(cur.copyWith(connection: conn));
    });

    _callSub = _repository.watchCall(callId).listen((call) {
      final cur = state.valueOrNull;
      if (cur == null) return;
      state = AsyncData(cur.copyWith(call: call));
    });

    // Bridge engine outbound signaling → SignalingService
    final signaling = ref.read(signalingServiceProvider);
    _signalingSub = _engine.outboundSignaling.listen((msg) {
      signaling.send(msg);
    });
  }

  void _cancelSubscriptions() {
    _mediaSub?.cancel();
    _connectionSub?.cancel();
    _callSub?.cancel();
    _signalingSub?.cancel();
    _mediaSub = null;
    _connectionSub = null;
    _callSub = null;
    _signalingSub = null;
  }
}

final activeCallProvider =
    AsyncNotifierProvider<ActiveCallNotifier, ActiveCallState?>(
  ActiveCallNotifier.new,
);
