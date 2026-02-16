import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/a2ui_surface_manager.dart';

void main() {
  group('A2uiSurfaceManager', () {
    late A2uiSurfaceManager manager;

    setUp(() {
      manager = A2uiSurfaceManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('initializes with catalog and surface host', () {
      expect(manager.catalog, isNotNull);
      expect(manager.surfaceHost, isNotNull);
      expect(manager.catalog.catalogId, 'clawfree-catalog');
    });

    test('addChunk feeds data to transport adapter', () async {
      final textFuture = manager.textStream.first;
      manager.addChunk('Hello World');
      expect(await textFuture, 'Hello World');
    });

    test('notifies on surfaceAdded', () async {
      final surfaceIdFuture = manager.surfaceAdded.first;
      
      // Send createSurface A2UI message
      manager.addChunk('''```json
{"version": "v0.9", "createSurface": {"surfaceId": "test-id", "catalogId": "clawfree-catalog"}}
```''');
      
      expect(await surfaceIdFuture, 'test-id');
    });

    test('notifies on surfaceUpdated (UpdateComponents)', () async {
      final surfaceIdFuture = manager.surfaceUpdated.first;
      
      // First create it
      manager.addChunk('''```json
{"version": "v0.9", "createSurface": {"surfaceId": "test-id", "catalogId": "clawfree-catalog"}}
```''');
      
      // Then update it
      manager.addChunk('''```json
{"version": "v0.9", "updateComponents": {"surfaceId": "test-id", "components": [{"id": "root", "component": "Column", "children": []}]}}
```''');
      
      expect(await surfaceIdFuture, 'test-id');
    });

    test('resetTransport clears parser state', () async {
      // Add partial text
      manager.addChunk('Part 1');
      
      manager.resetTransport();
      
      final textFuture = manager.textStream.first;
      manager.addChunk('Part 2');
      
      // If not reset, we might get "Part 1Part 2" depending on buffering, 
      // but new transport starts fresh.
      expect(await textFuture, 'Part 2');
    });

    test('buildSchemaJson returns valid JSON schema', () {
      final schema = manager.buildSchemaJson();
      expect(schema, contains('createSurface'));
      expect(schema, contains('updateComponents'));
      // The schema describes the message structure, not necessarily the specific catalog instance ID
      expect(schema, contains('v0.9'));
    });
    
    test('catalogRules returns expected rules string', () {
      expect(manager.catalogRules, contains('REQUIRED PROPERTIES'));
      expect(manager.catalogRules, contains('createSurface'));
    });
  });
}
