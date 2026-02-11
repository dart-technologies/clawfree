# genUI v0.9 Developer Primer

Quick reference for building with Flutter genUI v0.9 (A2UI "Prompt First" protocol).

---

## Architecture

v0.9 replaces the monolithic `ContentGenerator` / `GenUiController` pattern with three decoupled pieces:

| Component | Role | Key File |
|-----------|------|----------|
| **SurfaceController** | UI state engine; manages surfaces and catalogs | `lib/src/engine/surface_controller.dart` |
| **A2uiTransportAdapter** | Parses A2UI JSON from raw text stream | `lib/src/transport/a2ui_transport_adapter.dart` |
| **Surface** widget | Flutter widget that renders a surface | `lib/src/widgets/surface.dart` |

Supporting pieces: `SurfaceRegistry` (tracks active surfaces), `DataModelStore` (data binding), `Conversation` facade (high-level wrapper over controller + transport).

### Wiring Pattern

```dart
// 1. Create engine with catalog
final catalog = CoreCatalogItems.asCatalog();
final surfaceController = SurfaceController(catalogs: [catalog]);

// 2. Create transport adapter
final adapter = A2uiTransportAdapter();

// 3. Connect adapter output -> controller input
adapter.messageStream.listen(surfaceController.handleMessage);

// 4. Stream LLM text chunks into adapter
await for (final chunk in myLlmClient.stream(prompt)) {
  adapter.addChunk(chunk);
}
```

You bring your own LLM SDK -- no vendor wrapper packages needed.

---

## System Prompt Requirements

A2UI v0.9 is "Prompt First": the schema **must** be injected into the system prompt or the LLM will produce invalid JSON.

```dart
final schema = A2uiMessage.a2uiMessageSchema(catalog);

final systemPrompt = '''
You are a helpful assistant.

<a2ui_schema>
${schema.toJson(indent: '  ')}
</a2ui_schema>

${StandardCatalogEmbed.standardCatalogRules}

${PromptFragments.basicChat}
''';
```

Three required fragments:
1. **Schema** -- generated at runtime from active catalogs via `A2uiMessage.a2uiMessageSchema(catalog)`
2. **StandardCatalogEmbed.standardCatalogRules** -- validation rules the LLM follows during generation
3. **PromptFragments.basicChat** (or similar) -- behavioral instructions for chat context

---

## A2UI v0.9 Message Format

### Surface creation
```json
{ "createSurface": { "surfaceId": "...", "catalogId": "core", "theme": {} } }
```

### Flat component discriminator
```json
{ "component": "Text", "text": "Hello" }
{ "component": "Column", "children": [...] }
```
(v0.7/0.8 used key-based: `{ "Text": { "text": "Hello" } }`)

### Data binding
```json
{ "path": "/agentName" }
```
Literals are plain JSON values (no `literalString` wrapper).

---

## Key Differences from v0.7

| Area | v0.7 | v0.9 |
|------|------|------|
| Controller | `GenUiController(generator:)` | `SurfaceController(catalogs:)` |
| Transport | `ContentGenerator` (vendor-specific) | `A2uiTransportAdapter` + any SDK |
| Surface init | `beginRendering` | `createSurface` |
| Component format | Key-based `{ "Text": {...} }` | Flat `{ "component": "Text", ... }` |
| Widget name | `GenUiSurface` | `Surface` |
| Choice widget | `MultipleChoice` | `ChoicePicker` |
| Layout props | `distribution` / `alignment` | `justify` / `align` |
| Modal props | `entryPointChild` / `contentChild` | `trigger` / `content` |
| TextField value | `text` | `value` |
| Hint prop | `usageHint` | `variant` |
| User actions | `userAction` | `action` |
| System prompt | Optional | **Required** (schema + rules) |
| Provider packages | `genui_dartantic`, `genui_google_generative_ai`, etc. | Removed -- use SDKs directly |

---

## Reference Code: simple_chat

From `examples/simple_chat/lib/chat_session.dart`:

```dart
class ChatSession {
  final SurfaceController surfaceController;
  final A2uiTransportAdapter transportAdapter;

  ChatSession()
      : surfaceController = SurfaceController(
            catalogs: [CoreCatalogItems.asCatalog()]),
        transportAdapter = A2uiTransportAdapter() {
    // Adapter -> Controller
    transportAdapter.messageStream.listen(surfaceController.handleMessage);

    // User interactions
    surfaceController.onSubmit.listen((event) {
      sendMessage(event.toString());
    });
  }

  Future<void> sendMessage(String text) async {
    final schema = A2uiMessage.a2uiMessageSchema(catalog);
    final systemPrompt = '''
      <a2ui_schema>${schema.toJson(indent: '  ')}</a2ui_schema>
      ${StandardCatalogEmbed.standardCatalogRules}
    ''';

    await for (final chunk in llm.stream(text, systemPrompt: systemPrompt)) {
      transportAdapter.addChunk(chunk);
    }
  }
}
```

Higher-level alternative via facade:
```dart
final conversation = Conversation(
  transport: WebSocketTransport(url: 'ws://localhost:18789/genui'),
  catalogs: [CoreCatalogItems.asCatalog()],
);
```

---

## Known Test Gaps

- **`surface_widget_test.dart`** -- exists but is EMPTY (0 lines). P0 gap.
- **Missing widget tests**: `audio_player`, `video`, `widget_helpers` have no test files.
- **Interface tests**: 0% coverage (5 interface files untested). Low risk since tested indirectly.
- **Overall**: 62% file-level coverage (36 test files / 58 source files). Transport and Functions are at 100%.

---

## File Layout (v0.9 package)

```
packages/genui/lib/src/
  engine/         surface_controller, surface_registry, data_model_store, cleanup_strategy
  transport/      a2ui_transport_adapter, a2ui_parser_transformer
  facade/         conversation, chat_primitives, direct_call_integration/
  catalog/        core_catalog + 19 widget definitions (button, card, text, etc.)
  model/          a2ui_message, a2ui_schemas, catalog, data_model, standard_catalog_embed, ...
  interfaces/     transport, surface_context, surface_host, a2ui_message_sink
  widgets/        surface, fallback_widget, widget_utilities
  functions/      expression_parser, functions
  utils/          prompt_fragments, json_block_parser, cancellation, constants, logging
```
