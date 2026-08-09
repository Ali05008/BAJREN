# BAJREN Architecture – Phase 1

## Layers

```
Presentation (Riverpod AsyncNotifier + Widgets)
        ↓
Domain (Call, CallEngine, SignalingService, IceServerProvider)
        ↓
Data (WebRtcCallEngine, QualityController, InMemorySignaling, CallRepositoryImpl)
```

## WebRTC Flow

1. `startOutgoingCall` → create PeerConnection → getUserMedia → addTrack → createOffer → send via Signaling
2. Remote answer + ICE candidates arrive via `handleSignalingMessage`
3. `onTrack` delivers remote MediaStream
4. Stats collected every 2 s → QualityController → possible `replaceTrack`

## Adaptive Quality

- Health score from packet loss, RTT, jitter, frame drops
- One-step ladder: Ultra → High → Medium → Low → AudioOnly
- Cooldown 6 s + cancellable exponential backoff on `replaceTrack` failures

## Signaling

`SignalingService` is an abstract interface.  
Current implementation: `InMemorySignalingService` (process-local bus for tests/demo).  
Replace with Firebase Realtime / Firestore / Supabase Realtime / WebSocket without touching CallEngine.

## ICE / TURN

`IceServerProvider` returns STUN servers by default.  
TURN credentials **must** be fetched from a secure backend at runtime – never hardcoded.
