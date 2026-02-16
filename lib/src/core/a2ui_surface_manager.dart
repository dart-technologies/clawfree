import 'dart:async';

import 'package:genui/genui.dart';

import 'catalog.dart';

/// Manages the genUI v0.9 surface lifecycle: SurfaceController + A2uiTransportAdapter.
///
/// Decouples A2UI wiring from ChatSession so it can focus on conversation logic.
class A2uiSurfaceManager {
  A2uiSurfaceManager() {
    _catalog = getClawfreeCatalog();
    _surfaceController = SurfaceController(catalogs: [_catalog]);
    _transportAdapter = A2uiTransportAdapter();
    _wireTransport();

    // Track new surfaces
    _surfaceController.surfaceUpdates.listen((SurfaceUpdate update) {
      if (update is SurfaceAdded) {
        if (_notifiedSurfaceIds.add(update.surfaceId)) {
          _surfaceAddedController.add(update.surfaceId);
        }
      }
    });
  }

  late final Catalog _catalog;
  late final SurfaceController _surfaceController;
  late A2uiTransportAdapter _transportAdapter;
  StreamSubscription<A2uiMessage>? _transportSub;
  final _surfaceAddedController = StreamController<String>.broadcast();
  final _surfaceUpdatedController = StreamController<String>.broadcast();
  final _notifiedSurfaceIds = <String>{};

  void _wireTransport() {
    _transportSub?.cancel();
    _transportSub = _transportAdapter.incomingMessages.listen(
      (msg) {
        _surfaceController.handleMessage(msg);
        
        // Notify of updates to existing surfaces
        if (msg is UpdateComponents) {
          _surfaceUpdatedController.add(msg.surfaceId);
        } else if (msg is UpdateDataModel) {
          _surfaceUpdatedController.add(msg.surfaceId);
        }
      },
      onError: (Object error) {
        genUiLogger.warning('A2UI parse error: $error');
      },
    );
  }

  /// Reset the transport adapter to flush parser state between responses.
  ///
  /// Must be called before each new AI response to prevent text from the
  /// previous response leaking into the next one via the parser buffer.
  void resetTransport() {
    _transportSub?.cancel();
    _transportAdapter.dispose();
    _transportAdapter = A2uiTransportAdapter();
    _wireTransport();
  }

  /// The catalog used for schema generation.
  Catalog get catalog => _catalog;

  /// The surface host for building Surface widgets.
  SurfaceHost get surfaceHost => _surfaceController;

  /// Stream of user interactions from genUI surfaces.
  Stream<ChatMessage> get onSubmit => _surfaceController.onSubmit;

  /// Stream of new surface IDs as they're created.
  Stream<String> get surfaceAdded => _surfaceAddedController.stream;

  /// Stream of surface IDs as they're updated.
  Stream<String> get surfaceUpdated => _surfaceUpdatedController.stream;

  /// The text stream (non-A2UI portions of the response).
  Stream<String> get textStream => _transportAdapter.incomingText;

  /// Feed a chunk of the AI response into the A2UI pipeline.
  void addChunk(String chunk) => _transportAdapter.addChunk(chunk);

  /// Build the A2UI schema JSON for the system prompt.
  String buildSchemaJson() {
    return A2uiMessage.a2uiMessageSchema(_catalog).toJson(indent: '  ');
  }

  /// Standard catalog rules for the system prompt.
  String get catalogRules => r'''
**REQUIRED PROPERTIES:** You MUST include ALL required properties for every component, even if they are inside a template or will be bound to data.
- For 'Text', you MUST provide 'text'. If dynamic, use { "path": "..." }.
- For 'Image', you MUST provide 'url'. If dynamic, use { "path": "..." }.
- For 'Button', you MUST provide 'action'.
- For 'TextField', 'CheckBox', etc., you MUST provide 'label'.

**OUTPUT FORMAT:**
You must output a VALID JSON object representing one of the A2UI message types (`createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`).
- Do NOT use function blocks or tool calls for these messages.
- You can treat the A2UI schema as a specification for the JSON you typically output.
- You may include a brief conversational explanation before or after the JSON block if it helps the user, but the JSON block must be valid and complete.
- Ensure your JSON is fenced with ```json and ```.

**EXAMPLES:**

1. Create a surface:
```json
{
  "createSurface": {
    "surfaceId": "main",
    "catalogId": "clawfree-catalog",
    "sendDataModel": true
  }
}
```

2. Update components:
```json
{
  "updateComponents": {
    "surfaceId": "main",
    "components": [
      {
        // The root component MUST have id "root"
        "id": "root",
        "component": "Column",
        "justify": "start",
        "children": [
          "headerText",
          "content"
        ]
      }
    ]
  }
}
```

**IMPORTANT:**
- One of the components sent in one of the `updateComponents` MUST have id "root", or nothing will be displayed.
- Do NOT nest `components` inside `createSurface`. Use `updateComponents` to add components to a surface.
- `createSurface` ONLY sets up the surface (ID and catalog). It does NOT take content.
- To show a UI, you typically send a `createSurface` message (if the surface doesn't exist), followed by an `updateComponents` message.
''';

  /// Releases resources and closes internal streams.
  void dispose() {
    _surfaceAddedController.close();
    _surfaceUpdatedController.close();
    _surfaceController.dispose();
    _transportAdapter.dispose();
  }
}
