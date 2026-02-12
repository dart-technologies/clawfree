import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 上傳檔案
  Future<String> uploadFile({
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;
    await ref.putData(data, metadata);
    return await ref.getDownloadURL();
  }

  /// 上傳語音檔案
  Future<String> uploadVoiceFile({
    required String localPath,
    required String conversationId,
  }) async {
    final file = File(localPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'voices/$conversationId/$timestamp.m4a';
    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: 'audio/m4a');
    await ref.putFile(file, metadata);
    return await ref.getDownloadURL();
  }

  /// 取得下載連結
  Future<String> getDownloadURL(String path) async {
    return await _storage.ref().child(path).getDownloadURL();
  }

  /// 刪除檔案
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}
