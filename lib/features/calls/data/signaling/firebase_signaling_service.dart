import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

import '../../domain/services/call_engine.dart';
import '../../domain/services/signaling_service.dart';

/// Production signaling over Firebase Realtime Database.
///
/// Path layout:
///   signaling/{toUserId}/{pushId} = SignalingMessage JSON
///
/// Security rules (see docs/firebase_database.rules.json) ensure:
/// - Only authenticated users can write
/// - fromUserId must equal auth.uid
/// - Users only read their own inbox path
///
/// After processing, messages are removed to keep the node small.
class FirebaseSignalingService implements SignalingService {
  FirebaseSignalingService({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    Logger? logger,
  })  : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final Logger _log;

  final _incomingCtrl = StreamController<SignalingMessage>.broadcast();
  StreamSubscription<DatabaseEvent>? _sub;
  String? _userId;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<SignalingMessage> get incoming => _incomingCtrl.stream;

  @override
  Future<void> connect(String userId) async {
    await disconnect();

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'FirebaseSignalingService requires an authenticated user',
      );
    }
    if (user.uid != userId) {
      throw StateError(
        'userId must match FirebaseAuth.currentUser.uid (prevents spoofing)',
      );
    }

    _userId = userId;
    final ref = _db.ref('signaling/$userId');

    // Listen for new messages addressed to this user
    _sub = ref.onChildAdded.listen(
      (event) async {
        try {
          final raw = event.snapshot.value;
          if (raw is! Map) return;

          final map = Map<String, dynamic>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          );
          final msg = SignalingMessage.fromJson(map);

          // Defense in depth: ignore messages not addressed to us
          if (msg.toUserId.isNotEmpty && msg.toUserId != _userId) {
            _log.w('Dropping signaling message with mismatched toUserId');
            await event.snapshot.ref.remove();
            return;
          }

          // Ignore self-injected messages
          if (msg.fromUserId == _userId) {
            await event.snapshot.ref.remove();
            return;
          }

          _incomingCtrl.add(msg);

          // Consume message so it is not re-delivered
          await event.snapshot.ref.remove();
        } catch (e, st) {
          _log.e('Failed to parse signaling message', error: e, stackTrace: st);
          try {
            await event.snapshot.ref.remove();
          } catch (_) {}
        }
      },
      onError: (Object e, StackTrace st) {
        _log.e('Signaling listener error', error: e, stackTrace: st);
        _connected = false;
      },
    );

    _connected = true;
    _log.i('Firebase signaling connected as $userId');
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _connected = false;
    _userId = null;
  }

  @override
  Future<void> send(SignalingMessage message) async {
    if (!_connected) {
      throw StateError('SignalingService is not connected');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    // Force fromUserId to the authenticated uid (cannot be spoofed by client data alone;
    // security rules also enforce this server-side).
    final safe = SignalingMessage(
      callId: message.callId,
      type: message.type,
      payload: message.payload,
      fromUserId: user.uid,
      toUserId: message.toUserId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    if (safe.toUserId.isEmpty) {
      throw ArgumentError('toUserId is required');
    }
    if (safe.toUserId == user.uid) {
      throw ArgumentError('Cannot signal to self');
    }

    final ref = _db.ref('signaling/${safe.toUserId}').push();
    await ref.set(safe.toJson());
    _log.d('Sent ${safe.type.name} for call ${safe.callId}');
  }

  Future<void> dispose() async {
    await disconnect();
    await _incomingCtrl.close();
  }
}
