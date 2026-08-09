enum VideoQualityLevel {
  audioOnly,
  low,
  medium,
  high,
  ultra,
}

extension VideoQualityLevelX on VideoQualityLevel {
  String get label {
    switch (this) {
      case VideoQualityLevel.audioOnly:
        return 'Audio only';
      case VideoQualityLevel.low:
        return 'Low';
      case VideoQualityLevel.medium:
        return 'Medium';
      case VideoQualityLevel.high:
        return 'High';
      case VideoQualityLevel.ultra:
        return 'Ultra';
    }
  }
}
