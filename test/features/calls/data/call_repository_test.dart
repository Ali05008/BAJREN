import 'package:bajren/features/calls/data/repositories/call_repository_impl.dart';
import 'package:bajren/features/calls/domain/entities/call.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CallRepositoryImpl repo;

  setUp(() {
    repo = CallRepositoryImpl();
  });

  tearDown(() async {
    await repo.dispose();
  });

  test('startCall creates a ringing call', () async {
    final call = await repo.startCall(
      callerId: 'a',
      calleeId: 'b',
      type: CallType.video,
    );
    expect(call.status, CallStatus.ringing);
    expect(call.callerId, 'a');
    expect(call.calleeId, 'b');
    expect(call.type, CallType.video);
  });

  test('answerCall updates status', () async {
    final call = await repo.startCall(
      callerId: 'a',
      calleeId: 'b',
      type: CallType.voice,
    );
    await repo.answerCall(call.id);
    final updated = await repo.watchCall(call.id).first;
    expect(updated.status, CallStatus.connecting);
    expect(updated.answeredAt, isNotNull);
  });

  test('endCall sets duration', () async {
    final call = await repo.startCall(
      callerId: 'a',
      calleeId: 'b',
      type: CallType.voice,
    );
    await Future.delayed(const Duration(milliseconds: 50));
    await repo.endCall(call.id);
    final updated = await repo.watchCall(call.id).first;
    expect(updated.status, CallStatus.ended);
    expect(updated.duration, isNotNull);
  });
}
