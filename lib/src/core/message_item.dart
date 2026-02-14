/// A message in the chat conversation.
sealed class MessageItem {
  const MessageItem();

  factory MessageItem.user({required String text}) = UserMessage;
  factory MessageItem.aiText({required String text}) = AiTextMessage;
  factory MessageItem.surface({required String surfaceId}) = SurfaceMessage;
  factory MessageItem.error({required String text}) = ErrorMessage;

  /// Whether this is a user-sent message.
  bool get isUser => false;

  /// Whether this message represents a genUI surface.
  bool get isSurface => false;

  /// Whether this is an error message.
  bool get isError => false;

  /// The text content, or null for surface-only messages.
  String? get text => null;

  /// Setter for streaming text updates (only meaningful on [AiTextMessage]).
  set text(String? value) {}

  /// The surface ID, or null for non-surface messages.
  String? get surfaceId => null;
}

/// A message sent by the user.
class UserMessage extends MessageItem {
  UserMessage({required String text}) : _text = text;
  final String _text;

  @override
  String get text => _text;

  @override
  bool get isUser => true;
}

/// An AI-generated text message. [text] is mutable for streaming updates.
class AiTextMessage extends MessageItem {
  AiTextMessage({required String text}) : _text = text;
  String _text;

  @override
  String? get text => _text;

  @override
  set text(String? value) => _text = value ?? '';
}

/// A genUI surface message identified by [surfaceId].
class SurfaceMessage extends MessageItem {
  SurfaceMessage({required String surfaceId}) : _surfaceId = surfaceId;
  final String _surfaceId;

  @override
  String get surfaceId => _surfaceId;

  @override
  bool get isSurface => true;
}

/// An error message displayed with retry affordance.
class ErrorMessage extends MessageItem {
  ErrorMessage({required String text}) : _text = text;
  final String _text;

  @override
  String get text => _text;

  @override
  bool get isError => true;
}
