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

    // Wire transport -> engine
    _transportAdapter.incomingMessages.listen(
      _surfaceController.handleMessage,
      onError: (Object error) {
        genUiLogger.warning('A2UI parse error: $error');
      },
    );

    // Track new surfaces
    _surfaceController.surfaceUpdates.listen((SurfaceUpdate update) {
      if (update is SurfaceAdded) {
        _surfaceAddedController.add(update.surfaceId);
      }
    });
  }

  late final Catalog _catalog;
  late final SurfaceController _surfaceController;
  late final A2uiTransportAdapter _transportAdapter;
  final _surfaceAddedController = StreamController<String>.broadcast();

  /// The catalog used for schema generation.
  Catalog get catalog => _catalog;

  /// The surface host for building Surface widgets.
  SurfaceHost get surfaceHost => _surfaceController;

  /// Stream of user interactions from genUI surfaces.
  Stream<ChatMessage> get onSubmit => _surfaceController.onSubmit;

  /// Stream of new surface IDs as they're created.
  Stream<String> get surfaceAdded => _surfaceAddedController.stream;

  /// The text stream (non-A2UI portions of the response).
  Stream<String> get textStream => _transportAdapter.incomingText;

  /// Feed a chunk of the AI response into the A2UI pipeline.
  void addChunk(String chunk) => _transportAdapter.addChunk(chunk);

  /// Build the A2UI schema JSON for the system prompt.
  String buildSchemaJson() {
    return A2uiMessage.a2uiMessageSchema(_catalog).toJson(indent: '  ');
  }

  /// Standard catalog rules for the system prompt.
  String get catalogRules => StandardCatalogEmbed.standardCatalogRules;

  void dispose() {
    _surfaceAddedController.close();
    _surfaceController.dispose();
    _transportAdapter.dispose();
  }
}
