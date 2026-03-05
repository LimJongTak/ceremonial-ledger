import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw AuthException('Google 로그인 실패: $e');
    }
  }

  Future<UserCredential?> signInWithKakao() async {
    try {
      final _ = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      // Cloud Functions 백엔드 구현 필요
      throw UnimplementedError('백엔드 구현 필요');
    } catch (e) {
      throw AuthException('카카오 로그인 실패: $e');
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  Future<UserCredential> createAccount(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  String _message(String code) {
    switch (code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다';
      case 'wrong-password':
        return '비밀번호가 일치하지 않습니다';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다';
      default:
        return '로그인에 실패했습니다';
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
