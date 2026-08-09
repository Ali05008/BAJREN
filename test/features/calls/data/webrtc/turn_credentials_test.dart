import 'package:bajren/features/calls/data/webrtc/turn_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnCredentials', () {
    test('fromJson + prioritizes turns:443', () {
      final c = TurnCredentials.fromJson({
        'username': 'u',
        'credential': 'p',
        'ttl': 600,
        'uris': [
          'turn:t.example:3478',
          'turns:t.example:443',
          'turns:t.example:5349',
        ],
      });
      expect(c.username, 'u');
      expect(c.isExpired, isFalse);
      final ordered = c.prioritizedUris;
      expect(ordered.first, contains(':443'));
      expect(ordered.first.toLowerCase(), startsWith('turns:'));
    });

    test('toIceServerMaps includes auth fields', () {
      final c = TurnCredentials(
        username: 'u',
        credential: 'p',
        uris: ['turns:x:443'],
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final maps = c.toIceServerMaps();
      expect(maps.single['username'], 'u');
      expect(maps.single['credential'], 'p');
      expect(maps.single['urls'], 'turns:x:443');
    });

    test('isExpired', () {
      final c = TurnCredentials(
        username: 'u',
        credential: 'p',
        uris: ['turn:x'],
        expiresAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(c.isExpired, isTrue);
    });
  });
}
