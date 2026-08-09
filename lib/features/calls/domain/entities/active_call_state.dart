import 'package:equatable/equatable.dart';
import 'call.dart';
import 'call_media_state.dart';
import 'call_connection_state.dart';
import 'video_quality_level.dart';

class ActiveCallState extends Equatable {
  final Call call;
  final CallMediaState media;
  final CallConnectionState connection;
  final VideoQualityLevel currentQuality;
  final bool isQualityChanging;

  const ActiveCallState({
    required this.call,
    required this.media,
    required this.connection,
    required this.currentQuality,
    this.isQualityChanging = false,
  });

  ActiveCallState copyWith({
    Call? call,
    CallMediaState? media,
    CallConnectionState? connection,
    VideoQualityLevel? currentQuality,
    bool? isQualityChanging,
  }) {
    return ActiveCallState(
      call: call ?? this.call,
      media: media ?? this.media,
      connection: connection ?? this.connection,
      currentQuality: currentQuality ?? this.currentQuality,
      isQualityChanging: isQualityChanging ?? this.isQualityChanging,
    );
  }

  @override
  List<Object?> get props =>
      [call, media, connection, currentQuality, isQualityChanging];
}
