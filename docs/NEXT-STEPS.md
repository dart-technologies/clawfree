# Handoff Guide

Updated: Day 3 (Thu Feb 12)

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
flutter test        # 516 tests
flutter analyze     # 0 issues

# Zero-to-One QA (full Docker stack)
make stop && export ANTHROPIC_API_KEY=sk-ant-... && export GATEWAY_TOKEN=secret && make qa
# Wait 10-20s, then: make health
# Open http://localhost:8080 for onboarding flow
```

---

## Voice Services (DONE)

Real platform voice services are now active on native platforms (iOS, macOS, Android). Demo mode and web still use mocks.

**VoiceServiceFactory** (`lib/src/voice/voice_service_factory.dart`):
```dart
if (isDemo || kIsWeb) → MockTtsService + MockSttService
else                   → PlatformTtsService + PlatformSttService
```

**Mic permissions are configured:**
- iOS: `NSSpeechRecognitionUsageDescription` + `NSMicrophoneUsageDescription` in Info.plist
- macOS: `com.apple.security.device.audio-input` in DebugProfile + Release entitlements
- Android: `RECORD_AUDIO` permission + `<uses-feature android.hardware.microphone required="false" />`

**VoiceController API:**
```dart
final vc = sl.get<VoiceController>();
await vc.startListening(onResult: (transcript, isFinal) { ... });
await vc.stopListening();
await vc.speak('Agent saved!', onResult: onResult);
vc.continuousMode = true; // hands-free: auto-starts STT after TTS
```

**Remaining voice work:**
- Continuous listening / hands-free mode testing
- Push-to-talk fallback
- Voice-only mode (no screen touch)

---

## Apple Watch Voice Pipeline (DONE)

The standalone WatchCompanion SwiftUI app (`ios/WatchCompanion/`, 15 Swift files) provides native voice I/O on watchOS 10+:

- **SpeechRecognizer.swift** — `SFSpeechRecognizer` wrapper for on-device STT
- **TTSService.swift** + **WatchTTSService.swift** — `AVSpeechSynthesizer` with pitch/rate voice differentiation
- **ConnectivityProvider.swift** — `WCSession` bridge sends watch voice transcripts to Flutter via MethodChannel + HTTP POST fallback for simulator
- **EarconPlayer.swift** — Audio earcons (thinking, success, surface_arrival) with haptic fallback
- **DemoScriptRunner.swift** — 12-step automated demo (agent creation + travel booking flows)
- **UI Components** — ChatBubbleView, AgentConfigView, TripPlannerView, WaveformView
- **Testing** — `WatchCompanionUITests/WatchDemoFlowTest.swift` (XCUITest E2E)

The watch app syncs health state (agent count, listening state) from the iPhone app via `PulseMonitorView` heartbeat display.

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

## OpenClaw Integration (DONE)

**Agent creation is wired end-to-end:**
- `GatewayClient.createAgent()` POSTs config to `/agents` (accepts 200/201)
- `A2uiInteractionRouter._handleSaveAgent()` calls `createAgent` fire-and-forget after local save
- Auth token forwarded via `Authorization: Bearer <token>` header

**Gateway dual-proxy** (`infra/gateway/server.js`):
- `/v1/*` → Anthropic API (HTTPS, port 443)
- `/agents`, `/sessions`, `/onboard` → OpenClaw (HTTP, configurable host/port)
- Configure via env vars: `OPENCLAW_HOST` (default: localhost), `OPENCLAW_PORT` (default: 18790)

**Remaining integration:**
- `AgentStore` implements `AgentRepository` interface — swap with persistent backend for production

---

## QR Pairing & Device Sync (NEW)

End-to-end device pairing and Apple Watch synchronization are wired:

### Deep Link Handling

- **URL scheme**: `clawfree://pair?url=<gateway>&token=<token>`
- Registered in `ios/Runner/Info.plist` (`CFBundleURLSchemes`)
- Registered in `android/app/src/main/AndroidManifest.xml` (intent-filter)
- `app_links` package handles both cold-start (`getInitialLink()`) and warm-start (`uriLinkStream`) deep links in `main.dart`

### QR Scanning

- `QrScannerDialog` (`lib/src/ui/widgets/qr_scanner_dialog.dart`) uses `mobile_scanner` v6
- Accepts both raw HTTP gateway URLs and `clawfree://pair` deep links
- Race-condition guard (`_scanned` flag) prevents multi-pop from rapid barcode detection
- Gateway URLs are validated via `/health` probe before connecting (must return `service: "clawfree-gateway"`)

### Gateway /pair Endpoint

- `GET /pair` on the gateway (`infra/gateway/server.js`) returns a 302 redirect to the `clawfree://pair` deep link
- Browser QR scan → gateway redirect → app opens and auto-pairs
- `GATEWAY_TOKEN` env var is embedded in the deep link

### Apple Watch Sync

- **WatchSyncService** (`lib/src/core/watch_sync_service.dart`) listens to `HealthPoller` and `AgentRepository`
- Pushes `{activeAgentCount, healthLevel, isListening}` to native Swift via `MethodChannel("com.dart-technologies.clawfree/watch")`
- Uses `scheduleMicrotask` debounce to collapse rapid notifications
- **AppDelegate.swift** uses `updateApplicationContext` (replaces stale data) instead of `transferUserInfo` (unbounded queue)
- **ConnectivityProvider.swift** on the Watch receives context updates and drives `PulseMonitorView`
- Heartbeat pulse speed varies by health level: 1.2s (nominal), 0.6s (degraded), 0.3s (error)

### Testing

```bash
flutter test test/integration/pairing_sync_test.dart   # 7 tests
flutter test test/core/watch_sync_service_test.dart     # Unit tests
flutter test test/core/deep_link_test.dart              # Deep link + validation
flutter test test/core/gateway_pairing_test.dart        # URL construction
```

---

## Manual Visual QA Checklist

1. **Launch**: title + icon, API key field (non-demo), demo toggle, "Start Demo" button, QR scan button
2. **QR Pairing**: QR button → camera opens → scan gateway QR → snackbar confirms → session starts
3. **Deep Link**: open `clawfree://pair?url=http://192.168.1.5:18789&token=test` → app auto-connects
4. **Create Agent**: chip → user bubble → AI text streams → surface form fades in (name, model, tools, channels, save)
5. **Dashboard**: "Show my agents" → agent cards
6. **Multi-Turn**: "Create a Telegram bot" → form; "What else can you do?" → text only
7. **Adaptive**: resize 900px+ → side-by-side; below → inline surfaces
8. **Dark mode**: all text readable, genUI radio/checkbox labels visible
9. **Export**: download icon → snackbar
10. **Error**: invalid API key → retries → "Error:" message
11. **Watch Sync**: pair iPhone → Apple Watch shows agent count, health ring, listening state
