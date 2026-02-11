import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';

void main() {
  group('DemoCacheAiClient refinement keywords', () {
    late DemoCacheAiClient client;

    setUp(() {
      client = DemoCacheAiClient(chunkDelay: Duration.zero);
    });

    // -----------------------------------------------------------------------
    // Individual keyword matching
    // -----------------------------------------------------------------------

    test('"rename" returns refinement response with updateComponents', () async {
      final chunks = await client
          .sendStream('Rename it to GitDigest Bot',
              systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response, contains('agent-form-001'));
      expect(response, contains('updateComponents'));
      // Refinement must NOT create a new surface
      expect(response, isNot(contains('createSurface')));
      expect(response, contains('```json'));
    });

    test('"add" returns add-tool response with updateComponents', () async {
      final chunks = await client
          .sendStream('Add browser tool', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response, contains('updateComponents'));
      expect(response, contains('browser'));
      expect(response, isNot(contains('createSurface')));
      expect(response, contains('```json'));
    });

    test('"test" returns plain text about testing', () async {
      final chunks = await client
          .sendStream('Test the agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response.toLowerCase(), contains('ready to test'));
      // Plain text — no JSON block
      expect(response, isNot(contains('```json')));
    });

    test('"deploy" returns plain text about deployment', () async {
      final chunks = await client
          .sendStream('Deploy the agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response.toLowerCase(), contains('deploy'));
      expect(response, isNot(contains('```json')));
    });

    test('"help" returns help text', () async {
      final chunks = await client
          .sendStream('Help me out', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response, contains('Create an agent'));
      expect(response, isNot(contains('```json')));
    });

    test('"delete" returns deletion confirmation', () async {
      final chunks = await client
          .sendStream('Delete the agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      expect(response.toLowerCase(), contains('deleted'));
      expect(response, isNot(contains('```json')));
    });

    // -----------------------------------------------------------------------
    // Priority ordering: refinement keywords before creation keywords
    // -----------------------------------------------------------------------

    test('"rename the agent" matches rename, not create', () async {
      final chunks = await client
          .sendStream('Rename the agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      // rename response uses updateComponents only (no createSurface)
      expect(response, contains('updateComponents'));
      expect(response, isNot(contains('createSurface')));
    });

    test('"Add browser tool" matches add, not dashboard', () async {
      final chunks = await client
          .sendStream('Add browser tool', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      // add response updates the tools-picker
      expect(response, contains('tools-picker'));
      expect(response, contains('browser'));
      // Should not be the dashboard response
      expect(response, isNot(contains('dashboard-001')));
    });

    test('"test my agent now" matches test, not create', () async {
      final chunks = await client
          .sendStream('Test my agent now', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();

      // Plain text test response, not a create surface response
      expect(response.toLowerCase(), contains('ready to test'));
      expect(response, isNot(contains('createSurface')));
    });

    // -----------------------------------------------------------------------
    // Verify refinement responses use updateComponents NOT createSurface
    // -----------------------------------------------------------------------

    test('all refinement responses use updateComponents not createSurface',
        () async {
      // rename
      final rename = (await client
              .sendStream('rename it', systemPrompt: '', history: [])
              .toList())
          .join();
      expect(rename, contains('updateComponents'));
      expect(rename, isNot(contains('createSurface')));

      // add
      final add = (await client
              .sendStream('add a tool', systemPrompt: '', history: [])
              .toList())
          .join();
      expect(add, contains('updateComponents'));
      expect(add, isNot(contains('createSurface')));
    });

    // -----------------------------------------------------------------------
    // defaultResponses map structure
    // -----------------------------------------------------------------------

    test('defaultResponses contains all refinement keywords', () {
      final keys = DemoCacheAiClient.defaultResponses.keys.toList();
      expect(keys, contains('rename'));
      expect(keys, contains('add'));
      expect(keys, contains('test'));
      expect(keys, contains('deploy'));
      expect(keys, contains('help'));
      expect(keys, contains('delete'));
    });

    test('refinement keywords appear before creation keywords in map', () {
      final keys = DemoCacheAiClient.defaultResponses.keys.toList();
      final renameIdx = keys.indexOf('rename');
      final addIdx = keys.indexOf('add');
      final createIdx = keys.indexOf('create');
      final dashboardIdx = keys.indexOf('dashboard');

      // Refinement keywords must come before creation/dashboard keywords
      expect(renameIdx, lessThan(createIdx));
      expect(addIdx, lessThan(createIdx));
      expect(addIdx, lessThan(dashboardIdx));
    });

    test('rename response targets agent-form-001 surfaceId', () async {
      final chunks = await client
          .sendStream('rename', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('"surfaceId": "agent-form-001"'));
    });

    test('add response targets agent-form-001 surfaceId', () async {
      final chunks = await client
          .sendStream('add', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('"surfaceId": "agent-form-001"'));
    });
  });
}
