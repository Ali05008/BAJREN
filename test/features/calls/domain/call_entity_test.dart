import 'package:bajren/features/calls/domain/entities/call.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Call entity', () {
    test('copyWith updates status', () {
      final call = Call(
        id: '1',
        type: CallType.video,
        callerId: 'a',
        calleeId: 'b',
        status: CallStatus.ringing,
        startedAt: DateTime(2026, 1, 1),
      );
      final updated = call.copyWith(status: CallStatus.connected);
      expect(updated.status, CallStatus.connected);
      expect(updated.id, '1');
    });

    test('equality', () {
      final a = Call(
        id: '1',
        type: CallType.voice,
        callerId: 'a',
        calleeId: 'b',
        status: CallStatus.idle,
        startedAt: DateTime(2026, 1, 1),
      );
      final b = Call(
        id: '1',
        type: CallType.voice,
        callerId: 'a',
        calleeId: 'b',
        status: CallStatus.idle,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(a, equals(b));
    });
  });
}
