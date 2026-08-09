import '../../domain/entities/video_quality_level.dart';

class CallStats {
  final double packetLoss;
  final int rttMs;
  final double jitterMs;
  final int availableBitrateKbps;
  final int currentBitrateKbps;
  final int framesDropped;
  final int framesDecoded;
  final DateTime timestamp;

  const CallStats({
    required this.packetLoss,
    required this.rttMs,
    required this.jitterMs,
    required this.availableBitrateKbps,
    required this.currentBitrateKbps,
    required this.framesDropped,
    required this.framesDecoded,
    required this.timestamp,
  });
}

class QualityController {
  VideoQualityLevel _currentLevel = VideoQualityLevel.high;
  DateTime? _lastChangeAt;
  static const _cooldown = Duration(seconds: 6);

  final Future<void> Function(VideoQualityLevel level) onQualityChanged;
  final Future<void> Function() onForceAudioOnly;

  QualityController({
    required this.onQualityChanged,
    required this.onForceAudioOnly,
  });

  VideoQualityLevel get currentLevel => _currentLevel;

  Future<void> onStats(CallStats stats) async {
    final score = _calculateHealthScore(stats);
    final target = _scoreToLevel(score);

    if (target == _currentLevel) return;
    if (_lastChangeAt != null &&
        DateTime.now().difference(_lastChangeAt!) < _cooldown) {
      return;
    }

    final nextLevel = _stepToward(_currentLevel, target);
    await _applyLevel(nextLevel);
    _currentLevel = nextLevel;
    _lastChangeAt = DateTime.now();
  }

  double _calculateHealthScore(CallStats s) {
    double score = 100.0;

    if (s.packetLoss > 0.12) {
      score -= 50;
    } else if (s.packetLoss > 0.08) {
      score -= 35;
    } else if (s.packetLoss > 0.05) {
      score -= 20;
    } else if (s.packetLoss > 0.03) {
      score -= 10;
    }

    if (s.rttMs > 500) {
      score -= 30;
    } else if (s.rttMs > 350) {
      score -= 20;
    } else if (s.rttMs > 250) {
      score -= 10;
    }

    if (s.jitterMs > 80) {
      score -= 15;
    } else if (s.jitterMs > 50) {
      score -= 8;
    }

    if (s.availableBitrateKbps > 0 &&
        s.currentBitrateKbps > s.availableBitrateKbps * 0.9) {
      score -= 15;
    }

    final total = s.framesDecoded + s.framesDropped;
    final dropRatio = total == 0 ? 0.0 : s.framesDropped / total;
    if (dropRatio > 0.15) {
      score -= 20;
    } else if (dropRatio > 0.08) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  VideoQualityLevel _scoreToLevel(double score) {
    if (score >= 80) return VideoQualityLevel.ultra;
    if (score >= 65) return VideoQualityLevel.high;
    if (score >= 45) return VideoQualityLevel.medium;
    if (score >= 25) return VideoQualityLevel.low;
    return VideoQualityLevel.audioOnly;
  }

  VideoQualityLevel _stepToward(
    VideoQualityLevel current,
    VideoQualityLevel target,
  ) {
    final levels = VideoQualityLevel.values;
    final c = levels.indexOf(current);
    final t = levels.indexOf(target);
    if (t > c) return levels[c + 1];
    if (t < c) return levels[c - 1];
    return current;
  }

  Future<void> _applyLevel(VideoQualityLevel level) async {
    if (level == VideoQualityLevel.audioOnly) {
      await onForceAudioOnly();
    } else {
      await onQualityChanged(level);
    }
  }

  Future<void> forceLowQuality() async {
    await _applyLevel(VideoQualityLevel.low);
    _currentLevel = VideoQualityLevel.low;
    _lastChangeAt = DateTime.now();
  }
}
