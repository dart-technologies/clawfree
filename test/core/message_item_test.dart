import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/message_item.dart';

void main() {
  group('MessageItem', () {
    test('user message has correct properties', () {
      final msg = MessageItem.user(text: 'Hello');
      expect(msg.text, 'Hello');
      expect(msg.isUser, isTrue);
      expect(msg.isSurface, isFalse);
      expect(msg.surfaceId, isNull);
    });

    test('aiText message has correct properties', () {
      final msg = MessageItem.aiText(text: 'Response');
      expect(msg.text, 'Response');
      expect(msg.isUser, isFalse);
      expect(msg.isSurface, isFalse);
    });

    test('surface message has correct properties', () {
      final msg = MessageItem.surface(surfaceId: 'surface-01');
      expect(msg.surfaceId, 'surface-01');
      expect(msg.isUser, isFalse);
      expect(msg.isSurface, isTrue);
      expect(msg.text, isNull);
    });

    test('aiText text is mutable for streaming updates', () {
      final msg = MessageItem.aiText(text: '');
      expect(msg.text, '');
      msg.text = 'chunk1';
      expect(msg.text, 'chunk1');
      msg.text = '${msg.text} chunk2';
      expect(msg.text, 'chunk1 chunk2');
    });
  });
}
