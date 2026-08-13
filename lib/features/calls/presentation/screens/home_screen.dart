import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/firebase_ready.dart';
import '../../../../core/security/screen_capture_guard.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reports/presentation/report_user_sheet.dart';
import '../../domain/entities/call.dart';
import '../../domain/entities/call_connection_state.dart';
import '../providers/active_call_notifier.dart';
import '../providers/call_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _calleeController = TextEditingController();
  bool _video = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  void dispose() {
    _calleeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeCall = ref.watch(activeCallProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    // Incoming offers
    ref.listen(signalingSessionProvider, (_, __) {});
    final session = ref.watch(signalingSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BAJREN'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  user.uid.substring(0, user.uid.length.clamp(0, 8)),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(activeCallProvider.notifier).endCall();
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: firebaseReady ? Colors.teal.shade50 : Colors.orange.shade50,
            child: ListTile(
              dense: true,
              title: Text(
                firebaseReady
                    ? 'Production path: Firebase Auth + Signaling'
                    : 'Demo path: local auth (configure Firebase for 2-device calls)',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: user != null ? Text('uid: ${user.uid}') : null,
            ),
          ),
          StreamBuilder(
            stream: session.incomingOffers,
            builder: (context, snap) {
              final offer = snap.data;
              if (offer == null) return const SizedBox.shrink();
              final incomingType = offer.payload['callType'] == 'voice'
                  ? CallType.voice
                  : CallType.video;
              return Material(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: Icon(
                    incomingType == CallType.video
                        ? Icons.videocam
                        : Icons.call,
                    color: Colors.green.shade700,
                  ),
                  title: Text('اتصال وارد من ${offer.fromUserId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final call = Call(
                            id: offer.callId,
                            type: incomingType,
                            callerId: offer.fromUserId,
                            calleeId: user!.uid,
                            status: CallStatus.ringing,
                            startedAt: DateTime.now(),
                          );
                          await ref
                              .read(activeCallProvider.notifier)
                              .acceptIncomingCall(
                                call,
                                remoteOffer: offer.payload,
                              );
                        },
                        child: const Text('قبول'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(callEngineProvider)
                              .rejectCall(offer.callId);
                        },
                        child: const Text('رفض'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: activeCall.when(
              data: (state) {
                if (state != null) {
                  return ScreenCaptureGuard(
                    child: _CallView(state: state, currentUserId: user?.uid),
                  );
                }
                return _IdleView(
                  calleeController: _calleeController,
                  video: _video,
                  onVideoChanged: (v) => setState(() => _video = v),
                  onStart: () {
                    final me = user;
                    if (me == null) return;
                    ref.read(activeCallProvider.notifier).startOutgoingCall(
                          callerId: me.uid,
                          calleeId: _calleeController.text.trim(),
                          type: _video ? CallType.video : CallType.voice,
                        );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.calleeController,
    required this.video,
    required this.onVideoChanged,
    required this.onStart,
  });

  final TextEditingController calleeController;
  final bool video;
  final ValueChanged<bool> onVideoChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Start a call',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the other user\'s Firebase uid',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: calleeController,
            decoration: const InputDecoration(
              labelText: 'Callee UID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Video call'),
            value: video,
            onChanged: onVideoChanged,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onStart,
            icon: Icon(video ? Icons.videocam : Icons.call),
            label: Text(video ? 'Start Video Call' : 'Start Voice Call'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallView extends ConsumerStatefulWidget {
  const _CallView({required this.state, this.currentUserId});

  final dynamic state;
  final String? currentUserId;

  @override
  ConsumerState<_CallView> createState() => _CallViewState();
}

class _CallViewState extends ConsumerState<_CallView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;
  bool _speakerOn = true;
  MediaStream? _lastLocalStream;
  MediaStream? _lastRemoteStream;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    // RTCVideoRenderer MUST be initialized before srcObject is ever set,
    // otherwise flutter_webrtc throws "Call initialize before setting the
    // stream" and crashes the whole call screen.
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (!mounted) return;
    setState(() => _renderersReady = true);
    _syncStreams();
    // Default to speakerphone for video calls, earpiece for voice calls.
    final call = widget.state.call as Call;
    _speakerOn = call.type == CallType.video;
    ref.read(activeCallProvider.notifier).setSpeaker(_speakerOn);
  }

  @override
  void didUpdateWidget(covariant _CallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_renderersReady) _syncStreams();
  }

  void _syncStreams() {
    final media = widget.state.media;
    final MediaStream? local = media.localStream;
    final MediaStream? remote = media.remoteStream;
    if (local != _lastLocalStream) {
      _lastLocalStream = local;
      _localRenderer.srcObject = local;
    }
    if (remote != _lastRemoteStream) {
      _lastRemoteStream = remote;
      _remoteRenderer.srcObject = remote;
    }
  }

  @override
  void dispose() {
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _statusLabel(CallConnectionState connection, Call call) {
    switch (connection.status) {
      case CallStatus.idle:
      case CallStatus.ringing:
        return call.callerId == widget.currentUserId
            ? 'جارٍ الاتصال...'
            : 'اتصال وارد...';
      case CallStatus.connecting:
        return 'جارٍ الاتصال...';
      case CallStatus.connected:
        return connection.isReconnecting ? 'إعادة الاتصال...' : '';
      case CallStatus.reconnecting:
        return 'إعادة الاتصال...';
      case CallStatus.ended:
        return 'انتهت المكالمة';
      case CallStatus.failed:
        return connection.lastError ?? 'فشل الاتصال';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_renderersReady) {
      return const ColoredBox(
        color: Colors.black87,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    _syncStreams();

    final media = widget.state.media;
    final CallConnectionState connection = widget.state.connection;
    final Call call = widget.state.call;
    final otherUserId = widget.currentUserId == call.callerId
        ? call.calleeId
        : call.callerId;
    final hasRemoteVideo =
        media.remoteStream != null && call.type == CallType.video;
    final statusText = _statusLabel(connection, call);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasRemoteVideo)
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: const Color(0xFF0F0F14),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white12,
                    child: Text(
                      otherUserId.isNotEmpty
                          ? otherUserId.substring(0, 1).toUpperCase()
                          : '؟',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (statusText.isNotEmpty)
                    Text(
                      statusText,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 18),
                    ),
                ],
              ),
            ),
          ),
        if (media.localStream != null &&
            media.isCameraOn &&
            call.type == CallType.video)
          Positioned(
            right: 16,
            top: 16,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        if (otherUserId.isNotEmpty)
          Positioned(
            left: 16,
            top: 16,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                tooltip: 'Report user',
                onPressed: () => showReportUserSheet(
                  context,
                  targetUserId: otherUserId,
                  callId: call.id,
                ),
              ),
            ),
          ),
        if (hasRemoteVideo && statusText.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: 24,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: media.isMuted ? Icons.mic_off : Icons.mic,
                color: media.isMuted ? Colors.red : Colors.white24,
                onTap: () =>
                    ref.read(activeCallProvider.notifier).toggleMute(),
              ),
              _RoundButton(
                icon: _speakerOn ? Icons.volume_up : Icons.hearing,
                color: Colors.white24,
                onTap: () {
                  setState(() => _speakerOn = !_speakerOn);
                  ref
                      .read(activeCallProvider.notifier)
                      .setSpeaker(_speakerOn);
                },
              ),
              _RoundButton(
                icon: Icons.call_end,
                color: Colors.red,
                size: 64,
                onTap: () async {
                  await ref.read(activeCallProvider.notifier).endCall();
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              if (call.type == CallType.video)
                _RoundButton(
                  icon:
                      media.isCameraOn ? Icons.videocam : Icons.videocam_off,
                  color: media.isCameraOn ? Colors.white24 : Colors.red,
                  onTap: () =>
                      ref.read(activeCallProvider.notifier).toggleCamera(),
                ),
              if (call.type == CallType.video)
                _RoundButton(
                  icon: Icons.cameraswitch,
                  color: Colors.white24,
                  onTap: () =>
                      ref.read(activeCallProvider.notifier).switchCamera(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 52,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
