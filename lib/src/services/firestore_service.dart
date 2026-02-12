import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 發送訊息
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String userId,
    required bool isUser,
    String? audioUrl,
    String? messageType,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text': text,
      'userId': userId,
      'isUser': isUser,
      'audioUrl': audioUrl,
      'messageType': messageType ?? 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update conversation last message
    await updateConversationLastMessage(
      conversationId: conversationId,
      lastMessage: text,
    );
  }

  /// 監聽訊息
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// 取得對話列表 stream
  Stream<QuerySnapshot> getConversations() {
    return _firestore
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// 建立新對話
  Future<String> createConversation({String? title}) async {
    final doc = await _firestore.collection('conversations').add({
      'title': title ?? 'New Conversation',
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// 更新最後訊息摘要
  Future<void> updateConversationLastMessage({
    required String conversationId,
    required String lastMessage,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).set({
      'lastMessage': lastMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
