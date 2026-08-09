import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/call.dart';
import '../../domain/repositories/call_repository.dart';

class CallRepositoryImpl implements CallRepository {
  final _uuid = const Uuid();
  final _calls = <String, Call>{};
  final _controllers = <String, StreamController<Call>>{};
  final _historyController = StreamController<List<Call>>.broadcast();

  @override
  Future<Call> startCall({
    required String callerId,
    required String calleeId,
    required CallType type,
  }) async {
    final call = Call(
      id: _uuid.v4(),
      type: type,
      callerId: callerId,
      calleeId: calleeId,
      status: CallStatus.ringing,
      startedAt: DateTime.now(),
    );
    _calls[call.id] = call;
    _emit(call);
    return call;
  }

  @override
  Future<void> answerCall(String callId) async {
    final call = _calls[callId];
    if (call == null) return;
    final updated = call.copyWith(
      status: CallStatus.connecting,
      answeredAt: DateTime.now(),
    );
    _calls[callId] = updated;
    _emit(updated);
  }

  @override
  Future<void> rejectCall(String callId) async {
    final call = _calls[callId];
    if (call == null) return;
    final updated = call.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
    );
    _calls[callId] = updated;
    _emit(updated);
  }

  @override
  Future<void> endCall(String callId) async {
    final call = _calls[callId];
    if (call == null) return;
    final endedAt = DateTime.now();
    final duration = endedAt.difference(call.startedAt);
    final updated = call.copyWith(
      status: CallStatus.ended,
      endedAt: endedAt,
      duration: duration,
    );
    _calls[callId] = updated;
    _emit(updated);
  }

  @override
  Stream<Call> watchCall(String callId) {
    _controllers.putIfAbsent(
        callId, () => StreamController<Call>.broadcast());
    final existing = _calls[callId];
    if (existing != null) {
      scheduleMicrotask(() => _controllers[callId]!.add(existing));
    }
    return _controllers[callId]!.stream;
  }

  @override
  Stream<List<Call>> watchCallHistory({required String userId}) {
    return _historyController.stream;
  }

  void _emit(Call call) {
    _controllers[call.id]?.add(call);
    _historyController.add(_calls.values.toList());
  }

  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    await _historyController.close();
  }
}
