import '../entities/call.dart';

abstract class CallRepository {
  Future<Call> startCall({
    required String callerId,
    required String calleeId,
    required CallType type,
  });

  Future<void> answerCall(String callId);
  Future<void> rejectCall(String callId);
  Future<void> endCall(String callId);

  Stream<Call> watchCall(String callId);
  Stream<List<Call>> watchCallHistory({required String userId});
}
