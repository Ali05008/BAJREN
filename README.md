# BAJREN (باجْرِن)

Professional messaging & calling platform built with Flutter.

## Phase 1 – WebRTC Foundation (Current)

This release implements the **real-time calling foundation**:

- Clean Architecture (Domain / Data / Presentation)
- Real `flutter_webrtc` integration
  - `RTCPeerConnection`
  - `getUserMedia`
  - `addTrack` / `replaceTrack`
  - `createOffer` / `createAnswer`
  - ICE candidate exchange
- Adaptive bitrate / quality controller
- Cancellable exponential-backoff retry for quality changes
- Signaling abstraction (in-memory for now, ready for Firebase / Supabase / WebSocket)
- STUN configuration (TURN credentials must be supplied at runtime)
- Riverpod `AsyncNotifier` for active call state
- Unit tests for Domain + Data layers
- GitHub Actions: analyze → test → Android APK / AAB

## Requirements

- Flutter 3.24+
- Dart 3.5+
- Android SDK (for local builds) or GitHub Actions

## Getting Started (from phone / cloud)

1. Clone the repository.
2. No secrets are required for the current Phase 1 demo.
3. Push to GitHub → Actions will build the APK automatically.
4. Download the artifact `bajren-debug-apk`.

## Project Structure

```
lib/
├── app/
├── core/
└── features/calls/
    ├── domain/          # Entities, repositories, CallEngine contract
    ├── data/
    │   ├── webrtc/      # Real WebRtcCallEngine + QualityController
    │   ├── signaling/   # InMemorySignalingService (replaceable)
    │   └── repositories/
    └── presentation/    # Riverpod providers + demo UI
```

## Next Phases (not implemented yet)

- Authentication (phone + OTP)
- Chat / messaging
- Stories
- Production signaling (Firebase / Supabase)
- TURN credential server
- Group calls
- Push notifications for incoming calls

## License

Private – All rights reserved.
