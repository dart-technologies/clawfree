# CLAUDE.md — clawfree

## Project

**clawfree** is a hands-free AI agent orchestrator powered by Flutter genUI, built for the Anthropic Opus 4.6 hackathon (Feb 10-16, 2026).

Team **genUIne**: [Mike](https://cerebralvalley.ai/u/michow) (Flutter/infra) + [Roy](https://cerebralvalley.ai/u/roylin) (voice/OpenClaw)

## Tech Stack

- **Flutter** 3.38.9 (stable channel, macOS arm64)
- **genUI** v0.9 from `dart-technologies/genui` fork, branch `feature/v0.9-migration`
- **OpenClaw** gateway (TypeScript, Node.js >= 22)
- **Opus 4.6** (`claude-opus-4-6`) via Anthropic API
- **A2UI v0.9** protocol ("Prompt First")
- **Docker Compose** for local gateway
- **yarn** (preferred over npm)

## Architecture

```
Voice (STT) -> Flutter genUI Client -> OpenClaw Gateway -> Opus 4.6
                                                              |
Opus streams text + A2UI JSON -> Gateway -> Flutter renders Surface widgets
                                                              |
                                              Voice (TTS) confirms actions
```

Key v0.9 pattern (clawfree uses polyfilled catalog, not `CoreCatalogItems`):
```dart
final catalog = Catalog([...items...], catalogId: 'clawfree-catalog');
final surfaceController = SurfaceController(catalogs: [catalog]);
final adapter = A2uiTransportAdapter();
adapter.incomingMessages.listen(surfaceController.handleMessage);
// Stream Opus chunks into adapter:
adapter.addChunk(chunk);
// IMPORTANT: recreate adapter between responses (no reset API):
adapter.dispose();
adapter = A2uiTransportAdapter();
```

## Repo Structure

```
clawfree/
├── CLAUDE.md, GEMINI.md, README.md, LICENSE
├── assets/fonts/             # JetBrainsMono font family (Bold, Italic, Medium, Regular)
├── shaders/voice_blob.frag   # Fragment shader for VoiceOrb organic metaball animation
├── lib/
│   ├── main.dart
│   └── src/
│       ├── core/             # AI client, chat session, gateway client, health poller,
│       │                     # interaction router, demo_ai_client, remote_session,
│       │                     # catalog (A2UI component registry), platform_config
│       ├── voice/            # VoiceController (orchestrator), STT/TTS services,
│       │                     # EarconService, AcousticEarcons, VoiceServiceFactory
│       ├── video/            # ItineraryVideoGenerator (FFmpeg), VideoImageDownloader
│       └── ui/
│           ├── chat/         # A2UI components: badge, button (override), card (override),
│           │                 # chip, choice_picker (override), text (override),
│           │                 # text_field (override), animated, gap, grid, stack,
│           │                 # progress_bar, icon_resolver, responsive_container,
│           │                 # trip_map, video_player, input bar, message bubble/list,
│           │                 # surface panel/view
│           ├── health/       # HealthIndicators, HealthSparkline (vital signs framework)
│           ├── layouts/      # PhoneLayout, TabletLayout, VoiceOrb (shader-driven)
│           ├── mixins/       # HealthMonitorMixin, WatchSyncManager
│           ├── widgets/      # QrScannerDialog, RemoteSessionIndicator
│           ├── chat_screen.dart        # Slim orchestrator
│           ├── chat_screen_dialogs.dart # Extracted dialog flows
│           ├── clawfree_assets.dart
│           ├── clawfree_icons.dart
│           ├── spring_curve.dart
│           └── theme.dart         # Glassmorphism theme with JetBrainsMono typography
├── .github/workflows/        # CI: Flutter Analyze + Test + iOS Simulator Build
├── infra/                    # Docker Compose, Dockerfile, configs
├── docs/
│   ├── HACKATHON-PLAN.md     # Sprint plan + TODO checklist
│   ├── NEXT-STEPS.md         # Setup + handoff guide
│   ├── DISTRIBUTION.md       # Distribution & pairing guide
│   ├── INTEGRATION_MERGE.md  # ChatClaw merge spec
│   ├── WATCH_VOICE.md        # WatchOS voice implementation
│   └── background/           # Concise reference primers
├── test/                     # 492+ tests (unit + widget + e2e)
└── pubspec.yaml
```

## Dependencies (notable)

- `genui` — A2UI v0.9 runtime from `dart-technologies/genui` fork (local path override via `pubspec_overrides.yaml` during dev)
- `speech_to_text`, `flutter_tts` — STT/TTS platform wrappers
- `audioplayers` — synthesized audio earcons
- `ffmpeg_kit_flutter_new` — video generation from itinerary images
- `video_player` — native video playback
- `flutter_map`, `latlong2` — interactive trip maps
- `path_provider` — temp/cache directory resolution
- `json_schema_builder` — A2UI component schema definitions
- `logging` — structured logging
- `mocktail` (dev) — mock generation for unit tests

## Conventions

- Prefer **yarn** over npm for Node.js/OpenClaw dependencies
- genUI dependency via `dart-technologies/genui` fork (branch ref for CI, local path override via `pubspec_overrides.yaml` for dev)
- OpenClaw gateway runs in Docker on port 18789
- Flutter targets: web (Chrome), iOS (iPad), watchOS (Apple Watch voice)
- A2UI v0.9 flat component format: `{"component": "Text", "text": "Hello"}`
- System prompt must include `A2uiMessage.a2uiMessageSchema(catalog)` + inline catalog rules with `catalogId: "clawfree-catalog"`
- **VoiceController** is the single orchestrator for STT/TTS lifecycle; injected into `ChatSession` (not separate STT/TTS refs)
- **Theme**: glassmorphism design with `ClawfreeTheme.glassDecoration()`, transparent AppBar, `SpringCurve` animations
- **Typography**: JetBrainsMono font family throughout (w800 headlines, w700 titles, w400 body)
- **A2UI Catalog**: 26 components total — 7 polyfilled core (Column, Row, Image, Icon, Divider, Slider, CheckBox) + 12 custom (ResponsiveContainer, HealthSparkline, VideoPlayer, TripMap, Gap, BrandLogo, Badge, ProgressBar, Chip, Grid, Stack, Animated) + 5 core overrides (Card, Button, Text, ChoicePicker, TextField) + 2 custom form (AgentFormSurface, TravelSetupSurface via SurfaceController). All registered in `catalog.dart` with `catalogId: 'clawfree-catalog'`.
- **Polyfilled schemas** must include `'component': S.string(enumValues: ['ComponentName'])` for genUI's `_schemaMatchesType()` validation
- **Transport adapter** must be recreated between responses via `A2uiSurfaceManager.resetTransport()` — the parser has no reset API and its internal `_buffer` persists across `addChunk()` calls, causing text leakage
- Border radii standardized via `ClawfreeBorderRadius` constants (surface=20, interactive=16, element=12, small=8, tiny=4)
- Test animations: use `tester.pump()` + `tester.pump(Duration)` instead of `pumpAndSettle()` for animated widgets

## Key Files (genUI v0.9 reference)

- `../genui/examples/simple_chat/lib/chat_session.dart` — reference integration pattern
- `../genui/packages/genui/lib/src/engine/surface_controller.dart` — UI state engine
- `../genui/packages/genui/lib/src/transport/a2ui_transport_adapter.dart` — A2UI parser
- `../genui/packages/genui/lib/src/model/a2ui_message.dart` — schema generation
- `../genui/examples/verdure/server/` — A2UI server reference (Python)

## Hackathon Constraints

- Deadline: Mon Feb 16, 3:00 PM EST
- Submission: 3-min video + GitHub repo + 100-200 word summary
- Judging: Demo (30%), Impact (25%), Opus 4.6 Use (25%), Depth (20%)
- Must be built entirely during hackathon (no pre-existing work)
