import 'package:bajren/features/calls/domain/services/call_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SignalingMessage round-trip JSON', () {
    final msg = SignalingMessage(
      callId: 'c1',
      type: SignalingMessageType.offer,
      payload: {'sdp': 'v=0', 'type': 'offer'},
      fromUserId: 'a',
      toUserId: 'b',
      timestamp: 123,
    );
    final json = msg.toJson();
    expect(json['type'], 'offer');
    expect(json['fromUserId'], 'a');
    final back = SignalingMessage.fromJson(json);
    expect(back.callId, 'c1');
    expect(back.type, SignalingMessageType.offer);
    expect(back.payload['sdp'], 'v=0');
    expect(back.toUserId, 'b');
  });

  test('unknown type falls back to hangup', () {
    final back = SignalingMessage.fromJson({
      'callId': 'x',
      'type': 'unknown_type',
      'payload': {},
      'fromUserId': 'a',
      'toUserId': 'b',
    });
    expect(back.type, SignalingMessageType.hangup);
  });
}
