import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 當前用戶流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 匿名登入
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 當前用戶
  User? get currentUser => _auth.currentUser;
}
