# CLAUDE.md — clawfree

## Project

**clawfree** is a hands-free AI agentic orchestrator that lets anyone create and deploy OpenClaw agents using only voice — no coding, no typing required. Built with Flutter genUI for the Anthropic Opus 4.6 hackathon (Feb 10-16, 2026).

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
│           │                 # surface panel/view, agent_card, booking_summary,
│           │                 # flight_ticket, hotel_card, itinerary_day,
│           │                 # itinerary_header, itinerary_timeline
│           ├── health/       # HealthIndicators, HealthSparkline (vital signs framework)
│           ├── layouts/      # PhoneLayout (draggable history tray), TabletLayout,
│           │                 # VoiceOrb (shader-driven)
│           ├── mixins/       # HealthMonitorMixin, WatchSyncManager
│           ├── widgets/      # QrScannerDialog, RemoteSessionIndicator,
│           │                 # EmptyStateView, SuggestionChip, OnboardingModal
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
├── test/                     # 516 tests (unit + widget + e2e)
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
- `material_symbols_icons` — device-type and extended icon set
- `logging` — structured logging
- `shared_preferences` — onboarding persistence (first-launch detection)
- `mocktail` (dev) — mock generation for unit tests

## Conventions

- Prefer **yarn** over npm for Node.js/OpenClaw dependencies
- genUI dependency via `dart-technologies/genui` fork (branch ref for CI, local path override via `pubspec_overrides.yaml` for dev)
- OpenClaw gateway runs in Docker on port 18789
- Flutter targets: web (Chrome), iOS (iPad), watchOS (Apple Watch voice)
- A2UI v0.9 flat component format: `{"component": "Text", "text": "Hello"}`
- System prompt must include `A2uiMessage.a2uiMessageSchema(catalog)` + inline catalog rules with `catalogId: "clawfree-catalog"`
- **VoiceController** is the single orchestrator for STT/TTS lifecycle; injected into `ChatSession` (not separate STT/TTS refs). `TtsService` supports `setPitch()` and `setVoice()` for voice customization (used in demo driver for user/agent differentiation)
- **Theme**: HUD-style glassmorphism with `ClawfreeTheme.glassDecoration()`, ghost header (transparent AppBar), `SpringCurve` animations, ultra-thin borders (0.5px), `BackdropFilter` blur on glass cards
- **Design tokens**: `ClawfreeTheme.success/warning/error/info/neutral` (status colors), `onboardingMode/homeMode/agentBuilderMode` (session mode colors), `glassOverlayColor/glassBlur/itineraryAccent` (glass constants), `hudActive/scaffoldBlack/ratingGold` (accent colors), `hudBorder/hudSurfaceFaint/hudDivider/hudContainerColor/hudOverlayColor` (surface tokens), `hudTextPrimary/Secondary/Muted/Faint` (text opacity hierarchy). All color literals must use centralized tokens — no `Colors.white70`, `Colors.black.withValues(alpha:)`, or `Color(0xFF...)` in component files.
- **Typography**: JetBrainsMono font family throughout (w800–w900 headlines, w700 titles, w400 body). Use `ClawfreeTheme.technicalStyle()` for consistent technical text. UI labels are **uppercased** (`text.toUpperCase()`).
- **Icons**: Centralized via `ClawfreeIcons` (abstract final class). Platform-adaptive getters for `send`, `menuOpen`, `download`. Component icons: `arrowForward`, `receipt`, `flightTakeoff/Land`, `star/starBorder`, `timelineDot`, `pause`, `playArrow`, `brokenImage`. Device-type icons via `ClawfreeIcons.iconForDeviceType()` using `material_symbols_icons`. A2UI icon names resolved by `icon_resolver.dart` (50+ mappings). No raw `Icons.*` in component files.
- **A2UI Catalog**: 33 components total — 7 polyfilled core (Column, Row, Image, Icon, Divider, Slider, CheckBox) + 19 custom (ResponsiveContainer, HealthSparkline, VideoPlayer, TripMap, Gap, BrandLogo, Badge, ProgressBar, Chip, Grid, Stack, Animated, ItineraryHeader, ItineraryTimeline, ItineraryDay, AgentCard, BookingSummary, HotelCard, FlightTicket) + 5 core overrides (Card, Button, Text, ChoicePicker, TextField) + 2 custom form (AgentFormSurface, TravelSetupSurface via SurfaceController). All registered in `catalog.dart` with `catalogId: 'clawfree-catalog'`.
- **Polyfilled schemas** must include `'component': S.string(enumValues: ['ComponentName'])` for genUI's `_schemaMatchesType()` validation. Column supports `gap`, Row supports `wrap`/`spacing`.
- **Component variants**: Button adds `gradient` variant. ChoicePicker supports `layout: 'segmented' | 'wrap' | 'grid'`. Card `glass` variant uses real `BackdropFilter`.
- **Transport adapter** must be recreated between responses via `A2uiSurfaceManager.resetTransport()` — the parser has no reset API and its internal `_buffer` persists across `addChunk()` calls, causing text leakage
- **Surface manager** deduplicates `surfaceAdded` events and exposes a `surfaceUpdated` stream; `ChatSession._onSurfaceEvent()` handles both add and update (moves existing surfaces to end of message list)
- **Interaction debouncing**: `ChatSession` debounces rapid surface interactions (500ms) before routing through `A2uiInteractionRouter`
- Border radii standardized via `ClawfreeBorderRadius` constants (surface=20, interactive=16, element=12, small=8, tiny=4, pill=StadiumBorder)
- Test animations: use `tester.pump()` + `tester.pump(Duration)` instead of `pumpAndSettle()` for animated widgets. Widget tests with ChatSession must flush timers with an extra `tester.pump(Duration(seconds: 3))` at end to avoid "Timer is still pending" from debounce/mood timers.
- **PhoneLayout**: draggable history tray with snap-to-height animation (collapsed/200px/full), surface-first layout with scrollable genUI surface area
- **Stream processor** debounce interval: 100ms (stability over frame-rate)
- **Strict lint rules** in `analysis_options.yaml`: `prefer_final_locals`, `avoid_dynamic_calls`, `always_declare_return_types`, `unawaited_futures`. Fire-and-forget futures must be wrapped with `unawaited()`.
- **Onboarding modal**: `ChatScreen(showOnboarding: true)` shows architecture diagram on first launch; `SharedPreferences('has_seen_onboarding')` persists dismissal. Tests pass `showOnboarding: false` via `buildChatTestApp`.

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
