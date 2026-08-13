import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/firebase_ready.dart';
import '../../../../core/security/screen_capture_guard.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reports/presentation/report_user_sheet.dart';
import '../../domain/entities/call.dart';
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
              return Material(
                color: Colors.green.shade50,
                child: ListTile(
                  title: Text('Incoming call from ${offer.fromUserId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final call = Call(
                            id: offer.callId,
                            type: CallType.video,
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
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(callEngineProvider)
                              .rejectCall(offer.callId);
                        },
                        child: const Text('Reject'),
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

class _CallView extends ConsumerWidget {
  const _CallView({required this.state, this.currentUserId});

  final dynamic state;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = state.media;
    final connection = state.connection;
    final Call call = state.call;
    final otherUserId =
        currentUserId == call.callerId ? call.calleeId : call.callerId;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (media.remoteStream != null)
          RTCVideoView(
            RTCVideoRenderer()..srcObject = media.remoteStream,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: Colors.black87,
            child: Center(
              child: Text(
                connection.status.toString().split('.').last,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          ),
        if (media.localStream != null)
          Positioned(
            right: 16,
            top: 16,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(
                RTCVideoRenderer()..srcObject = media.localStream,
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
                icon: Icons.call_end,
                color: Colors.red,
                size: 64,
                onTap: () => ref.read(activeCallProvider.notifier).endCall(),
              ),
              _RoundButton(
                icon: media.isCameraOn ? Icons.videocam : Icons.videocam_off,
                color: media.isCameraOn ? Colors.white24 : Colors.red,
                onTap: () =>
                    ref.read(activeCallProvider.notifier).toggleCamera(),
              ),
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
