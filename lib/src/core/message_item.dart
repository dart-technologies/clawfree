/// A message in the chat conversation.
class MessageItem {
  MessageItem._({this.text, this.surfaceId, required this.isUser});

  factory MessageItem.user({required String text}) =>
      MessageItem._(text: text, isUser: true);

  factory MessageItem.aiText({required String text}) =>
      MessageItem._(text: text, isUser: false);

  factory MessageItem.surface({required String surfaceId}) =>
      MessageItem._(surfaceId: surfaceId, isUser: false);

  String? text;
  final String? surfaceId;
  final bool isUser;

  bool get isSurface => surfaceId != null;
  bool get isError =>
      !isUser && !isSurface && text != null && text!.startsWith('Error:');
}
