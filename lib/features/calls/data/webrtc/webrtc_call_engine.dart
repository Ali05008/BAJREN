import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/call.dart';
import '../../domain/entities/call_media_state.dart';
import '../../domain/entities/call_connection_state.dart';
import '../../domain/entities/video_quality_level.dart';
import '../../domain/services/call_engine.dart';
import '../../domain/services/ice_server_provider.dart';
import 'quality_controller.dart';
import 'peer_connection_factory.dart';

class WebRtcCallEngine implements CallEngine {
  WebRtcCallEngine({
    required IceServerProvider iceServerProvider,
    Logger? logger,
  })  : _iceServerProvider = iceServerProvider,
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final IceServerProvider _iceServerProvider;
  final Logger _log;
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, MediaStream> _localStreams = {};
  final Map<String, RTCRtpSender> _videoSenders = {};
  final Map<String, QualityController> _qualityControllers = {};
  final Map<String, Timer> _statsTimers = {};

  final Map<String, StreamController<CallMediaState>> _mediaCtrls = {};
  final Map<String, StreamController<CallConnectionState>> _connCtrls = {};

  final _outboundSignalingCtrl =
      StreamController<SignalingMessage>.broadcast();

  CancelableOperation<bool>? _ongoingQualityChange;
  VideoQualityLevel? _pendingQualityLevel;
  String _currentFacingMode = 'user';

  final Map<String, int> _iceRestartAttempts = {};
  /// callId -> (localUserId, remoteUserId) for ICE candidate routing
  final Map<String, (String, String)> _callPeerIds = {};
  final Map<String, DateTime> _lastIceRestartAt = {};
  static const int _maxIceRestarts = 3;
  static const Duration _iceRestartBaseDelay = Duration(seconds: 2);

  static const _maxQualityRetries = 3;
  static const _baseRetryDelay = Duration(milliseconds: 600);

  // ---------------------------------------------------------------------------
  // CallEngine API
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    // flutter_webrtc does not require global init on most platforms,
    // but we keep the hook for future native setup.
    _log.i('CallEngine initialized');
  }

  @override
  Stream<SignalingMessage> get outboundSignaling =>
      _outboundSignalingCtrl.stream;

  @override
  Future<void> startOutgoingCall(Call call) async {
    _ensureControllers(call.id);
    _callPeerIds[call.id] = (call.callerId, call.calleeId);

    final pc = await _createPeerConnection(call.id);
    final localStream = await _createLocalStream(call.type);
    _localStreams[call.id] = localStream;

    for (final track in localStream.getTracks()) {
      final sender = await pc.addTrack(track, localStream);
      if (track.kind == 'video') {
        _videoSenders[call.id] = sender;
      }
    }

    _emitMedia(call.id, CallMediaState(
      localStream: localStream,
      isCameraOn: call.type == CallType.video,
    ));

    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': call.type == CallType.video,
    });
    await pc.setLocalDescription(offer);

    _outboundSignalingCtrl.add(SignalingMessage(
      callId: call.id,
      type: SignalingMessageType.offer,
      payload: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      fromUserId: call.callerId,
      toUserId: call.calleeId,
    ));

    _startStatsMonitoring(call.id);
    _emitConnection(call.id, const CallConnectionState(
      status: CallStatus.connecting,
    ));
  }

  @override
  Future<void> acceptIncomingCall(
    Call call, {
    required Map<String, dynamic> remoteOffer,
  }) async {
    _ensureControllers(call.id);
    // Local user is callee when answering
    _callPeerIds[call.id] = (call.calleeId, call.callerId);

    final pc = await _createPeerConnection(call.id);
    final localStream = await _createLocalStream(call.type);
    _localStreams[call.id] = localStream;

    for (final track in localStream.getTracks()) {
      final sender = await pc.addTrack(track, localStream);
      if (track.kind == 'video') {
        _videoSenders[call.id] = sender;
      }
    }

    _emitMedia(call.id, CallMediaState(
      localStream: localStream,
      isCameraOn: call.type == CallType.video,
    ));

    final offer = RTCSessionDescription(
      remoteOffer['sdp'] as String?,
      remoteOffer['type'] as String?,
    );
    await pc.setRemoteDescription(offer);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _outboundSignalingCtrl.add(SignalingMessage(
      callId: call.id,
      type: SignalingMessageType.answer,
      payload: {
        'sdp': answer.sdp,
        'type': answer.type,
      },
      fromUserId: call.calleeId,
      toUserId: call.callerId,
    ));

    _startStatsMonitoring(call.id);
    _emitConnection(call.id, const CallConnectionState(
      status: CallStatus.connecting,
    ));
  }

  @override
  Future<void> rejectCall(String callId) async {
    _outboundSignalingCtrl.add(SignalingMessage(
      callId: callId,
      type: SignalingMessageType.reject,
      payload: const {},
      fromUserId: '',
      toUserId: '',
    ));
    await _cleanupCall(callId);
  }

  @override
  Future<void> hangUp(String callId) async {
    await _cancelOngoingQualityChange();
    _outboundSignalingCtrl.add(SignalingMessage(
      callId: callId,
      type: SignalingMessageType.hangup,
      payload: const {},
      fromUserId: '',
      toUserId: '',
    ));
    await _cleanupCall(callId);
  }

  @override
  Future<void> toggleMute(bool muted) async {
    for (final stream in _localStreams.values) {
      for (final track in stream.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
  }

  @override
  Future<void> toggleCamera(bool enabled) async {
    for (final stream in _localStreams.values) {
      for (final track in stream.getVideoTracks()) {
        track.enabled = enabled;
      }
    }
  }

  @override
  Future<void> switchCamera() async {
    _currentFacingMode =
        _currentFacingMode == 'user' ? 'environment' : 'user';
    for (final entry in _localStreams.entries) {
      final stream = entry.value;
      final videoTracks = stream.getVideoTracks();
      if (videoTracks.isEmpty) continue;
      // Helper from flutter_webrtc
      await Helper.switchCamera(videoTracks.first);
    }
  }

  @override
  Future<void> setSpeaker(bool enabled) async {
    await Helper.setSpeakerphoneOn(enabled);
  }

  @override
  Stream<CallMediaState> mediaStateStream(String callId) {
    _ensureControllers(callId);
    return _mediaCtrls[callId]!.stream;
  }

  @override
  Stream<CallConnectionState> connectionStateStream(String callId) {
    _ensureControllers(callId);
    return _connCtrls[callId]!.stream;
  }

  @override
  Future<void> handleSignalingMessage(SignalingMessage message) async {
    final pc = _peers[message.callId];
    if (pc == null) {
      _log.w('No peer for call ${message.callId}');
      return;
    }

    switch (message.type) {
      case SignalingMessageType.answer:
        final answer = RTCSessionDescription(
          message.payload['sdp'] as String?,
          message.payload['type'] as String?,
        );
        await pc.setRemoteDescription(answer);
        break;

      case SignalingMessageType.iceCandidate:
        final candidate = RTCIceCandidate(
          message.payload['candidate'] as String?,
          message.payload['sdpMid'] as String?,
          message.payload['sdpMLineIndex'] as int?,
        );
        await pc.addCandidate(candidate);
        break;

      case SignalingMessageType.hangup:
      case SignalingMessageType.reject:
        await _cleanupCall(message.callId);
        break;

      case SignalingMessageType.offer:
        // Incoming offer while already in a call → renegotiation (future)
        break;

      case SignalingMessageType.renegotiate:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    await _cancelOngoingQualityChange();
    for (final id in _peers.keys.toList()) {
      await _cleanupCall(id);
    }
    await _outboundSignalingCtrl.close();
  }

  // ---------------------------------------------------------------------------
  // PeerConnection factory
  // ---------------------------------------------------------------------------

  Future<RTCPeerConnection> _createPeerConnection(String callId) async {
    final factory = PeerConnectionFactory(iceServerProvider: _iceServerProvider);
    final pc = await factory.create();

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      final peers = _callPeerIds[callId];
      _outboundSignalingCtrl.add(SignalingMessage(
        callId: callId,
        type: SignalingMessageType.iceCandidate,
        payload: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        fromUserId: peers?.$1 ?? '',
        toUserId: peers?.$2 ?? '',
      ));
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isEmpty) return;
      final remoteStream = event.streams.first;
      _emitMedia(callId, CallMediaState(remoteStream: remoteStream));
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      _log.d('ICE state [$callId]: $state');
      CallStatus status = CallStatus.connecting;
      bool reconnecting = false;

      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          status = CallStatus.connected;
          _iceRestartAttempts[callId] = 0;
          // Diagnostics: direct vs relay (no sensitive data)
          _logSelectedCandidatePair(callId, pc);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          status = CallStatus.reconnecting;
          reconnecting = true;
          _qualityControllers[callId]?.forceLowQuality();
          _scheduleIceRestart(callId, pc);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          status = CallStatus.reconnecting;
          reconnecting = true;
          _scheduleIceRestart(callId, pc);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          status = CallStatus.ended;
          break;
        default:
          status = CallStatus.connecting;
      }

      _emitConnection(
        callId,
        CallConnectionState(
          status: status,
          iceConnectionState: state.toString(),
          isReconnecting: reconnecting,
        ),
      );
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      _log.d('PC state [$callId]: $state');
    };

    _peers[callId] = pc;
    return pc;
  }

  /// ICE restart with exponential backoff. Does not expose credentials.
  Future<void> _scheduleIceRestart(String callId, RTCPeerConnection pc) async {
    final attempts = _iceRestartAttempts[callId] ?? 0;
    if (attempts >= _maxIceRestarts) {
      _log.w('ICE restart limit reached for $callId');
      _emitConnection(
        callId,
        const CallConnectionState(
          status: CallStatus.failed,
          lastError: 'ice_restart_exhausted',
        ),
      );
      return;
    }

    final last = _lastIceRestartAt[callId];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 1)) {
      return; // debounce
    }

    final delay = _iceRestartBaseDelay * (1 << attempts);
    _iceRestartAttempts[callId] = attempts + 1;
    _lastIceRestartAt[callId] = DateTime.now();

    _log.i('ICE restart #${attempts + 1} for $callId in ${delay.inSeconds}s');
    await Future.delayed(delay);

    // Peer may have been cleaned up
    if (_peers[callId] != pc) return;

    try {
      await pc.restartIce();
      _log.i('ICE restartIce() invoked for $callId');
    } catch (e) {
      _log.w('restartIce failed: $e');
    }
  }

  /// Logs whether the selected pair is host/srflx (direct) or relay (TURN).
  /// Never logs IPs, ports, or credentials.
  Future<void> _logSelectedCandidatePair(
    String callId,
    RTCPeerConnection pc,
  ) async {
    try {
      final reports = await pc.getStats();
      String? localType;
      String? remoteType;
      for (final r in reports) {
        if (r.type == 'candidate-pair') {
          final values = r.values;
          final state = values['state']?.toString() ?? '';
          final nominated = values['nominated'] == true ||
              values['selected'] == true ||
              state == 'succeeded';
          if (!nominated) continue;

          // Find local/remote candidate types via ids if present
          final localId = values['localCandidateId']?.toString();
          final remoteId = values['remoteCandidateId']?.toString();
          for (final c in reports) {
            if (c.type == 'local-candidate' && c.id == localId) {
              localType = c.values['candidateType']?.toString();
            }
            if (c.type == 'remote-candidate' && c.id == remoteId) {
              remoteType = c.values['candidateType']?.toString();
            }
          }
        }
      }

      final path = _classifyPath(localType, remoteType);
      _log.i('Call $callId media path: $path '
          '(local=${localType ?? "unknown"}, remote=${remoteType ?? "unknown"})');
    } catch (e) {
      _log.d('Could not classify ICE path: $e');
    }
  }

  String _classifyPath(String? local, String? remote) {
    final types = {local, remote};
    if (types.contains('relay')) return 'turn_relay';
    if (types.contains('srflx') || types.contains('prflx')) {
      return 'direct_reflexive';
    }
    if (types.contains('host')) return 'direct_host';
    return 'unknown';
  }

  Future<MediaStream> _createLocalStream(CallType type) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': type == CallType.video
          ? {
              'facingMode': _currentFacingMode,
              'width': {'ideal': 960},
              'height': {'ideal': 540},
              'frameRate': {'ideal': 25},
            }
          : false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    return stream;
  }

  // ---------------------------------------------------------------------------
  // Adaptive quality + replaceTrack + cancellable retry
  // ---------------------------------------------------------------------------

  @override
  Future<void> applyVideoQuality(
    String callId,
    VideoQualityLevel level,
  ) async {
    if (level == VideoQualityLevel.audioOnly) {
      await _cancelOngoingQualityChange();
      await _switchToAudioOnly(callId);
      return;
    }

    await _cancelOngoingQualityChange();
    _pendingQualityLevel = level;
    final constraints = _constraintsForLevel(level);

    _ongoingQualityChange = CancelableOperation.fromFuture(
      _replaceVideoTrackWithRetry(
        callId: callId,
        constraints: constraints,
        targetLevel: level,
      ),
      onCancel: () {
        _log.d('Quality change to $level cancelled');
      },
    );

    try {
      final success =
          await _ongoingQualityChange!.valueOrCancellation(false);
      if (success == true) {
        _log.i('Quality changed to $level');
      }
    } finally {
      if (_pendingQualityLevel == level) {
        _ongoingQualityChange = null;
        _pendingQualityLevel = null;
      }
    }
  }

  Future<void> _cancelOngoingQualityChange() async {
    final op = _ongoingQualityChange;
    if (op != null && !op.isCompleted) {
      await op.cancel();
    }
    _ongoingQualityChange = null;
  }

  Future<bool> _replaceVideoTrackWithRetry({
    required String callId,
    required Map<String, dynamic> constraints,
    required VideoQualityLevel targetLevel,
  }) async {
    int attempt = 0;

    while (attempt < _maxQualityRetries) {
      if (_pendingQualityLevel != targetLevel) return false;

      attempt++;
      final success =
          await _replaceVideoTrack(callId, constraints, targetLevel);
      if (success) return true;
      if (attempt >= _maxQualityRetries) break;

      if (!await _isRetryable(callId)) break;

      final delay = _backoff(attempt);
      final cancelled = await _interruptibleDelay(delay, targetLevel);
      if (cancelled) return false;
    }
    return false;
  }

  Future<bool> _replaceVideoTrack(
    String callId,
    Map<String, dynamic> constraints,
    VideoQualityLevel targetLevel,
  ) async {
    final pc = _peers[callId];
    final oldStream = _localStreams[callId];
    if (pc == null || oldStream == null) return false;

    if (pc.connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        pc.connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      return false;
    }

    MediaStream? newStream;
    MediaStreamTrack? newVideoTrack;

    try {
      newStream = await navigator.mediaDevices.getUserMedia(constraints);
      final tracks = newStream.getVideoTracks();
      if (tracks.isEmpty) {
        throw Exception('getUserMedia returned no video track');
      }
      newVideoTrack = tracks.first;

      var sender = _videoSenders[callId];
      if (sender == null) {
        final senders = await pc.getSenders();
        sender = senders.firstWhere(
          (s) => s.track?.kind == 'video',
          orElse: () => throw Exception('No video sender found'),
        );
        _videoSenders[callId] = sender;
      }

      await sender.replaceTrack(newVideoTrack);

      // Stop old video tracks
      for (final t in List<MediaStreamTrack>.from(oldStream.getVideoTracks())) {
        try {
          await t.stop();
          oldStream.removeTrack(t);
        } catch (e) {
          _log.w('Failed to stop old track: $e');
        }
      }

      oldStream.addTrack(newVideoTrack);
      _localStreams[callId] = oldStream;

      try {
        await newStream.dispose();
      } catch (_) {}

      _emitMedia(callId, CallMediaState(localStream: oldStream));
      return true;
    } catch (e, st) {
      _log.e('replaceTrack failed', error: e, stackTrace: st);
      await _safeCleanup(newVideoTrack, newStream);
      return false;
    }
  }

  Future<void> _switchToAudioOnly(String callId) async {
    final stream = _localStreams[callId];
    if (stream == null) return;

    try {
      final sender = _videoSenders[callId];
      if (sender != null) {
        await sender.replaceTrack(null);
      }
    } catch (e) {
      _log.w('replaceTrack(null) failed: $e');
    }

    for (final t in List<MediaStreamTrack>.from(stream.getVideoTracks())) {
      try {
        await t.stop();
        stream.removeTrack(t);
      } catch (e) {
        _log.w('Error stopping video track: $e');
      }
    }

    _emitMedia(
      callId,
      CallMediaState(localStream: stream, isCameraOn: false),
    );
  }

  Future<void> _safeCleanup(MediaStreamTrack? track, MediaStream? stream) async {
    try {
      if (track != null) await track.stop();
    } catch (_) {}
    try {
      if (stream != null) await stream.dispose();
    } catch (_) {}
  }

  Duration _backoff(int attempt) {
    final exp = _baseRetryDelay * (1 << (attempt - 1));
    final jitter = Duration(milliseconds: Random().nextInt(400));
    final total = exp + jitter;
    return total > const Duration(seconds: 4)
        ? const Duration(seconds: 4)
        : total;
  }

  Future<bool> _isRetryable(String callId) async {
    final pc = _peers[callId];
    if (pc == null) return false;
    final s = pc.connectionState;
    if (s == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      return false;
    }
    return true;
  }

  Future<bool> _interruptibleDelay(
    Duration delay,
    VideoQualityLevel target,
  ) async {
    final end = DateTime.now().add(delay);
    const step = Duration(milliseconds: 100);
    while (DateTime.now().isBefore(end)) {
      if (_pendingQualityLevel != target) return true;
      await Future.delayed(step);
    }
    return false;
  }

  Map<String, dynamic> _constraintsForLevel(VideoQualityLevel level) {
    switch (level) {
      case VideoQualityLevel.ultra:
        return {
          'audio': false,
          'video': {
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
            'frameRate': {'ideal': 30},
            'facingMode': _currentFacingMode,
          },
        };
      case VideoQualityLevel.high:
        return {
          'audio': false,
          'video': {
            'width': {'ideal': 960},
            'height': {'ideal': 540},
            'frameRate': {'ideal': 25},
            'facingMode': _currentFacingMode,
          },
        };
      case VideoQualityLevel.medium:
        return {
          'audio': false,
          'video': {
            'width': {'ideal': 640},
            'height': {'ideal': 360},
            'frameRate': {'ideal': 20},
            'facingMode': _currentFacingMode,
          },
        };
      case VideoQualityLevel.low:
        return {
          'audio': false,
          'video': {
            'width': {'ideal': 480},
            'height': {'ideal': 270},
            'frameRate': {'ideal': 15},
            'facingMode': _currentFacingMode,
          },
        };
      case VideoQualityLevel.audioOnly:
        return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Stats monitoring
  // ---------------------------------------------------------------------------

  void _startStatsMonitoring(String callId) {
    _qualityControllers[callId] = QualityController(
      onQualityChanged: (level) => applyVideoQuality(callId, level),
      onForceAudioOnly: () =>
          applyVideoQuality(callId, VideoQualityLevel.audioOnly),
    );

    _statsTimers[callId]?.cancel();
    _statsTimers[callId] = Timer.periodic(const Duration(seconds: 2), (_) async {
      final pc = _peers[callId];
      if (pc == null) return;
      try {
        final reports = await pc.getStats();
        final stats = _parseStats(reports);
        if (stats != null) {
          await _qualityControllers[callId]?.onStats(stats);
        }
      } catch (e) {
        _log.w('getStats failed: $e');
      }
    });
  }

  CallStats? _parseStats(List<StatsReport> reports) {
    double packetLoss = 0;
    int rtt = 0;
    double jitter = 0;
    int availableBw = 0;
    int currentBw = 0;
    int framesDropped = 0;
    int framesDecoded = 0;

    for (final r in reports) {
      final values = r.values;
      if (r.type == 'outbound-rtp' && values['kind'] == 'video') {
        final packetsSent = (values['packetsSent'] as num?)?.toInt() ?? 0;
        final packetsLost = (values['packetsLost'] as num?)?.toInt() ?? 0;
        if (packetsSent + packetsLost > 0) {
          packetLoss = packetsLost / (packetsSent + packetsLost);
        }
        currentBw =
            ((values['bytesSent'] as num?)?.toInt() ?? 0) * 8 ~/ 1000;
        framesDropped =
            (values['framesDropped'] as num?)?.toInt() ?? framesDropped;
      }
      if (r.type == 'remote-inbound-rtp') {
        rtt = ((values['roundTripTime'] as num?)?.toDouble() ?? 0 * 1000)
            .toInt();
        jitter =
            ((values['jitter'] as num?)?.toDouble() ?? 0) * 1000;
      }
      if (r.type == 'candidate-pair' && values['state'] == 'succeeded') {
        availableBw =
            ((values['availableOutgoingBitrate'] as num?)?.toInt() ?? 0) ~/
                1000;
      }
      if (r.type == 'inbound-rtp' && values['kind'] == 'video') {
        framesDecoded =
            (values['framesDecoded'] as num?)?.toInt() ?? framesDecoded;
        framesDropped =
            (values['framesDropped'] as num?)?.toInt() ?? framesDropped;
      }
    }

    return CallStats(
      packetLoss: packetLoss,
      rttMs: rtt,
      jitterMs: jitter,
      availableBitrateKbps: availableBw,
      currentBitrateKbps: currentBw,
      framesDropped: framesDropped,
      framesDecoded: framesDecoded,
      timestamp: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _ensureControllers(String callId) {
    _mediaCtrls.putIfAbsent(
        callId, () => StreamController<CallMediaState>.broadcast());
    _connCtrls.putIfAbsent(
        callId, () => StreamController<CallConnectionState>.broadcast());
  }

  void _emitMedia(String callId, CallMediaState partial) {
    final ctrl = _mediaCtrls[callId];
    if (ctrl == null || ctrl.isClosed) return;
    // Simple emit – in a more advanced version we would merge with previous.
    ctrl.add(partial);
  }

  void _emitConnection(String callId, CallConnectionState state) {
    final ctrl = _connCtrls[callId];
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(state);
  }

  Future<void> _cleanupCall(String callId) async {
    _statsTimers[callId]?.cancel();
    _statsTimers.remove(callId);
    _qualityControllers.remove(callId);

    final pc = _peers.remove(callId);
    if (pc != null) {
      try {
        await pc.close();
      } catch (_) {}
    }

    final stream = _localStreams.remove(callId);
    if (stream != null) {
      for (final t in stream.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }

    _videoSenders.remove(callId);
    _iceRestartAttempts.remove(callId);
    _callPeerIds.remove(callId);
    _lastIceRestartAt.remove(callId);

    await _mediaCtrls[callId]?.close();
    await _connCtrls[callId]?.close();
    _mediaCtrls.remove(callId);
    _connCtrls.remove(callId);

    _emitConnection(
      callId,
      const CallConnectionState(status: CallStatus.ended),
    );
  }
}
