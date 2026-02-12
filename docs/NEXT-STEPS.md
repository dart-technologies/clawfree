# Handoff Guide

Updated: Day 2 (Tue Feb 11)

---

## Running Locally

```bash
# macOS (recommended)
flutter run -d macos --dart-define=ANTHROPIC_API_KEY=sk-ant-...
flutter run -d macos --dart-define=DEMO_MODE=true

# Chrome (needs gateway)
cd infra && docker compose up -d && cd ..
flutter run -d chrome --dart-define=DEMO_MODE=true

# iOS
flutter run -d "iPhone 17 Pro"

# Tests
flutter test        # 333 tests
flutter analyze     # 0 issues

# Zero-to-One QA (full Docker stack)
make stop && export ANTHROPIC_API_KEY=sk-ant-... && export GATEWAY_TOKEN=secret && make qa
# Wait 10-20s, then: make health
# Open http://localhost:8080 for onboarding flow
```

---

## Switching to Real Voice

Edit `lib/src/voice/voice_service_factory.dart` — one-line change:

```dart
abstract final class VoiceServiceFactory {
  static ({TtsService tts, SttService stt}) create({bool isDemo = false}) {
    if (isDemo) return (tts: MockTtsService(), stt: MockSttService());
    return (tts: PlatformTtsService(), stt: PlatformSttService());
  }
}
```

**Already wired:**
- `VoiceServiceFactory.create()` called in `main.dart:_start()`, registered in `ServiceLocator`
- `VoiceController` coordinates STT↔TTS (pauses TTS when STT starts, `continuousMode`)
- `ChatInputBar` receives `SttService` via widget param
- `ChatSession` receives `TtsService` for action confirmations

**VoiceController API:**

```dart
final vc = sl.get<VoiceController>();
await vc.startListening(onResult: (transcript, isFinal) { ... });
await vc.stopListening();
await vc.speak('Agent saved!', onResult: onResult);
vc.continuousMode = true; // hands-free: auto-starts STT after TTS
```

**Platform requirements:**
- Device-level mic permission testing (iOS/macOS)
- macOS: `com.apple.security.network.client` entitlement (already in DebugProfile.entitlements)
- macOS: minimum deployment target 11.0 for speech_to_text

---

## Gateway Connectivity (NEW)

Live gateway communication is wired end-to-end:

- **`GatewayClient`** (`lib/src/core/gateway_client.dart`) — HTTP client for `/health`, `/agents`, `/onboard`, `/sessions` with auth headers, connection state tracking
- **`HealthPoller`** (`lib/src/core/health_poller.dart`) — 15s periodic polling, maps `GatewayHealthResponse` to 5-section `HealthState`, fetches remote sessions in parallel
- **`RemoteSession`** (`lib/src/core/remote_session.dart`) — model for connected devices; `iconForDeviceType()` maps form factors to Material icons; `defaultDemoSessions()` provides plausible placeholders when no gateway is connected
- **`connect_gateway` action** — "Connect existing" onboarding shortcut: updates GatewayClient URL/token, skips to Home mode
- **Agent sync** — on transition to Home mode, `ChatSession._syncAgentsFromGateway()` imports remote agents
- **`main.dart`** creates `GatewayClient` for non-demo mode, registers in `ServiceLocator`, passes to `ChatSession`
- **`ChatScreen`** creates `HealthPoller` when `gatewayClient` is available, starts polling on Home transition

The "Connect Existing" path is available during onboarding — say "Connect existing" or "Link my gateway" to trigger the `connect_gateway` A2UI action.

## OpenClaw Integration Points

- `A2uiInteractionRouter.handle()` returns sealed `InteractionResult` — extend with new subtypes for OpenClaw actions
- `ChatSession._handleSurfaceInteraction()` switches on result type — add OpenClaw agent API calls here
- `AgentStore` implements `AgentRepository` interface — swap with persistent backend

---

## Manual Visual QA Checklist

1. **Launch**: title + icon, API key field (non-demo), demo toggle, "Start Demo" button
2. **Create Agent**: chip → user bubble → AI text streams → surface form fades in (name, model, tools, channels, save)
3. **Dashboard**: "Show my agents" → agent cards
4. **Multi-Turn**: "Create a Telegram bot" → form; "What else can you do?" → text only
5. **Adaptive**: resize 900px+ → side-by-side; below → inline surfaces
6. **Dark mode**: all text readable, genUI radio/checkbox labels visible
7. **Export**: download icon → snackbar
8. **Error**: invalid API key → retries → "Error:" message
