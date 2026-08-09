import 'package:bajren/features/calls/data/webrtc/quality_controller.dart';
import 'package:bajren/features/calls/domain/entities/video_quality_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QualityController', () {
    late List<VideoQualityLevel> changes;
    late QualityController controller;

    setUp(() {
      changes = [];
      controller = QualityController(
        onQualityChanged: (level) async => changes.add(level),
        onForceAudioOnly: () async => changes.add(VideoQualityLevel.audioOnly),
      );
    });

    test('starts at high', () {
      expect(controller.currentLevel, VideoQualityLevel.high);
    });

    test('degrades on high packet loss', () async {
      final badStats = CallStats(
        packetLoss: 0.15,
        rttMs: 100,
        jitterMs: 10,
        availableBitrateKbps: 1000,
        currentBitrateKbps: 800,
        framesDropped: 5,
        framesDecoded: 100,
        timestamp: DateTime.now(),
      );
      await controller.onStats(badStats);
      // After cooldown bypass we still only step one level
      expect(changes, isNotEmpty);
    });

    test('forceLowQuality works', () async {
      await controller.forceLowQuality();
      expect(controller.currentLevel, VideoQualityLevel.low);
      expect(changes, contains(VideoQualityLevel.low));
    });
  });
}
