# CLAUDE.md — clawfree

## Project

**clawfree** is a hands-free, voice-enabled Flutter genUI frontend for OpenClaw, built for the Anthropic Opus 4.6 hackathon (Feb 10-16, 2026).

Team **genUIne**: [Mike](https://cerebralvalley.ai/u/michow) (Flutter/infra) + [Roy](https://cerebralvalley.ai/u/roylin) (voice/OpenClaw)

## Tech Stack

- **Flutter** 3.38.9 (stable channel, macOS arm64)
- **genUI** v0.9 from `flutter/genui` branch `feature/v0.9-migration`
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

Key v0.9 pattern:
```dart
final catalog = CoreCatalogItems.asCatalog();
final surfaceController = SurfaceController(catalogs: [catalog]);
final adapter = A2uiTransportAdapter();
adapter.messageStream.listen(surfaceController.handleMessage);
// Stream Opus chunks into adapter:
adapter.addChunk(chunk);
```

## Repo Structure

```
clawfree/
├── CLAUDE.md, README.md, LICENSE
├── lib/
│   ├── main.dart
│   └── src/
│       ├── core/            # AI client, chat session, interaction router, prompt library
│       ├── voice/           # STT/TTS services, VoiceController, VoiceServiceFactory
│       └── ui/
│           ├── chat/        # Decomposed chat widgets (input bar, messages, surface panel)
│           ├── chat_screen.dart   # Slim orchestrator (~267 lines)
│           ├── clawfree_assets.dart
│           ├── clawfree_icons.dart
│           ├── theme.dart
│           └── voice_input_widget.dart
├── infra/                   # Docker Compose, Dockerfile, configs
├── docs/
│   ├── HACKATHON-PLAN.md    # Sprint plan + TODO checklist
│   ├── NEXT-STEPS.md        # Setup + handoff guide
│   └── background/          # Concise reference primers
├── test/                    # 176 tests (unit + widget + e2e)
└── pubspec.yaml
```

## Conventions

- Prefer **yarn** over npm for Node.js/OpenClaw dependencies
- genUI dependency via local path (`path: ../genui/packages/genui`) during dev, git ref for submission
- OpenClaw gateway runs in Docker on port 18789
- Flutter targets: web (Chrome), iOS (iPad), watchOS (Apple Watch voice)
- A2UI v0.9 flat component format: `{"component": "Text", "text": "Hello"}`
- System prompt must include `A2uiMessage.a2uiMessageSchema(catalog)` + `StandardCatalogEmbed.standardCatalogRules`

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
