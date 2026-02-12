# clawfree

Hands-free AI agent creation powered by Opus 4.6 and Flutter genUI.

Speak to create, configure, and interact with AI agents through dynamically generated UIs. No typing, no JSON editing, no code.

## How It Works

1. **Speak** -- tell clawfree what agent you want ("Create a Telegram bot that summarizes my GitHub notifications")
2. **See** -- Opus 4.6 generates an interactive configuration UI in real-time via the A2UI protocol
3. **Refine** -- continue speaking to adjust settings, Opus updates the UI live
4. **Deploy** -- save and your agent is live on OpenClaw, connected to 18+ messaging channels

## Architecture

```
Voice Input (STT)
    │
Flutter genUI Client ──── A2UI protocol ──── OpenClaw Gateway
    │                                             │
Surface widgets                              Opus 4.6
    │                                        (reasoning +
Voice Output (TTS)                           UI generation)
```

- **Flutter genUI v0.9** renders dynamic UI from A2UI JSON at runtime
- **OpenClaw** provides the AI gateway with 18+ messaging channels, tool execution, and agent management
- **Opus 4.6** generates both conversational responses AND structured UI components in a single streaming call

## Quick Start

### Prerequisites

- Flutter >= 3.35.7 (stable channel)
- Docker & Docker Compose (for web/gateway)
- Anthropic API key (or use demo mode)

### Run in Demo Mode (no API key needed)

```bash
git clone https://github.com/dart-technologies/clawfree.git
cd clawfree
flutter pub get
flutter run -d macos --dart-define=DEMO_MODE=true
```

### Run with Opus 4.6

```bash
# macOS (direct API)
flutter run -d macos --dart-define=ANTHROPIC_API_KEY=sk-ant-...

# With Firebase + OpenClaw (full features)
flutter run -d macos \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
  --dart-define=OPENCLAW_GATEWAY_URL=http://localhost:3000 \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id

# Chrome (requires gateway)
cd infra && docker compose up -d && cd ..
flutter run -d chrome
```

### Using the Makefile

```bash
make help           # Show all targets
make demo           # Run in demo mode (no API key)
make run            # Run on macOS with API key
make test           # Run all 176 tests
make analyze        # Run Dart analyzer (0 issues)
make gateway        # Start CORS gateway (Docker)
make gateway-down   # Stop gateway
make icons          # Regenerate macOS app icons
make clean          # Clean build artifacts
```

### Run Tests

```bash
flutter test        # 176 tests
flutter analyze     # 0 issues
```

## Project Structure

```
lib/src/
├── core/               # AI client, chat session, interaction router, prompt library
│   ├── chat_session.dart        # Session state + generation (~249 lines)
│   ├── interaction_router.dart  # A2UI event routing (sealed InteractionResult)
│   ├── prompt_library.dart      # System prompt text
│   └── ...                      # AI client, surface manager, agent store
├── ui/
│   ├── chat/                    # Decomposed chat widgets
│   │   ├── chat_input_bar.dart      # Platform-adaptive input + voice + send
│   │   ├── chat_message_bubble.dart # Messages + context menu + animations
│   │   ├── chat_message_list.dart   # List + empty state + suggestion chips
│   │   ├── chat_surface_panel.dart  # Side panel + surface indicator
│   │   └── chat_surface_view.dart   # Surface + error boundary + shimmer
│   ├── chat_screen.dart         # Slim orchestrator (~267 lines)
│   ├── clawfree_assets.dart     # Asset path constants
│   ├── clawfree_icons.dart      # Platform-adaptive icon registry
│   └── theme.dart               # Material 3, light/dark, Apple adaptive
└── voice/
    ├── voice_controller.dart    # STT↔TTS coordination
    ├── voice_service_factory.dart # Service creation
    └── ...                      # STT/TTS interfaces + platform implementations
test/                            # 176 tests (unit + widget + e2e)
infra/
├── docker-compose.yml
├── .env.local                   # ANTHROPIC_API_KEY (gitignored)
└── gateway/                     # Lightweight Node.js CORS proxy
```

## Key Features

- **Streaming generation** -- Opus 4.6 streams text + A2UI JSON simultaneously
- **Self-correction** -- invalid A2UI JSON triggers automatic retry with feedback
- **Platform-adaptive theming** -- Cupertino on iOS/macOS, Material on Android/web
- **Adaptive layout** -- phone (single column) / tablet+desktop (side-by-side at 900px+)
- **Multi-turn refinement** -- update existing UIs via follow-up requests (updateComponents)
- **Message animations** -- slide-up entrance, shimmer loading skeletons, voice pulse
- **Error recovery** -- retry button on failures, error boundary for render crashes
- **Demo mode** -- 12 cached responses covering creation, refinement, and dashboard flows
- **Voice ready** -- STT/TTS interfaces with platform implementations
- **Agent store** -- in-memory CRUD with auto-save from form submissions, export with copy

## Team genUIne

Built for the [Built with Opus 4.6](https://cerebralvalley.ai/e/claude-code-hackathon) hackathon (Feb 10-16, 2026).

- [Michael Chow](https://cerebralvalley.ai/u/michow) -- Flutter genUI engine, A2UI protocol, infrastructure, demo system
- [Roy Lin](https://cerebralvalley.ai/u/roylin) -- Voice interactions (STT/TTS, continuous listening, hands-free mode), Firebase backend (Auth, Firestore, Storage), Apple Watch companion, OpenClaw service integration, UI animations

## License

MIT
