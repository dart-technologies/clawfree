import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/watch_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatchVoiceEvent', () {
    test('fromMap parses filePath and timestamp', () {
      final event = WatchVoiceEvent.fromMap({
        'filePath': '/tmp/voice.m4a',
        'timestamp': 1707700000000,
      });

      expect(event.filePath, '/tmp/voice.m4a');
      expect(event.timestamp.millisecondsSinceEpoch, 1707700000000);
    });

    test('fromMap uses DateTime.now() when timestamp is null', () {
      final before = DateTime.now();
      final event = WatchVoiceEvent.fromMap({
        'filePath': '/tmp/voice.m4a',
        'timestamp': null,
      });
      final after = DateTime.now();

      expect(event.filePath, '/tmp/voice.m4a');
      expect(event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(event.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('fromMap parses voice_command with text', () {
      final event = WatchVoiceEvent.fromMap({
        'type': 'voice_command',
        'text': 'plan tokyo trip',
        'timestamp': 1707700000000,
      });

      expect(event.type, 'voice_command');
      expect(event.text, 'plan tokyo trip');
      expect(event.isTextCommand, isTrue);
      expect(event.filePath, isNull);
    });

    test('isTextCommand is false for voice file events', () {
      final event = WatchVoiceEvent.fromMap({
        'type': 'voice',
        'filePath': '/tmp/voice.m4a',
        'timestamp': 1707700000000,
      });

      expect(event.isTextCommand, isFalse);
    });

    test('isTextCommand is false when text is null', () {
      final event = WatchVoiceEvent.fromMap({
        'type': 'voice_command',
        'timestamp': 1707700000000,
      });

      expect(event.isTextCommand, isFalse);
    });

    test('toJson roundtrips correctly for voice_command', () {
      final event = WatchVoiceEvent(
        text: 'hello world',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1707700000000),
        type: 'voice_command',
      );

      final json = event.toJson();
      expect(json['type'], 'voice_command');
      expect(json['text'], 'hello world');
      expect(json['timestamp'], 1707700000000);
      expect(json.containsKey('filePath'), isFalse);
    });
  });

  group('WatchBridge MethodChannel', () {
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('art.dart.clawfree/watch'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'isWatchReachable') return true;
          return null;
        },
      );
    });

    test('sendReplyToWatch invokes sendReply with text', () async {
      await WatchBridge.sendReplyToWatch('Hello from AI');

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'sendReply');
      expect((methodCalls.first.arguments as Map)['text'], 'Hello from AI');
    });

    test('isWatchReachable returns true when native reports true', () async {
      final reachable = await WatchBridge.isWatchReachable;
      expect(reachable, isTrue);

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'isWatchReachable');
    });

    test('isWatchReachable returns false when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('art.dart.clawfree/watch'),
        (MethodCall call) async => null,
      );

      final reachable = await WatchBridge.isWatchReachable;
      expect(reachable, isFalse);
    });

    test('sendReplyToWatch sends empty string without error', () async {
      await WatchBridge.sendReplyToWatch('');

      expect(methodCalls.length, 1);
      expect((methodCalls.first.arguments as Map)['text'], '');
    });
  });
}
