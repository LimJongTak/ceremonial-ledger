import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Google 로그인 ───────────────────────────────────────────
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

  // ── 카카오 로그인 ───────────────────────────────────────────
  // 카카오 SDK → Firebase email/password 방식으로 연결
  Future<UserCredential?> signInWithKakao() async {
    try {
      // 1. 카카오 로그인 (카카오톡 앱 우선, 없으면 웹)
      await (await isKakaoTalkInstalled()
          ? UserApi.instance.loginWithKakaoTalk()
          : UserApi.instance.loginWithKakaoAccount());

      // 2. 카카오 사용자 정보 가져오기
      final kakaoUser = await UserApi.instance.me();
      final kakaoId = kakaoUser.id;
      final nickname =
          kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자';

      // 3. Firebase 계정 구성 (카카오 ID 기반 고유 이메일)
      final firebaseEmail = 'kakao_$kakaoId@kakao.cl.user';
      final firebasePassword = 'kakao_${kakaoId}_cl2024!';

      // 4. Firebase 로그인 시도 → 없으면 계정 생성
      UserCredential cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(
          email: firebaseEmail,
          password: firebasePassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'INVALID_LOGIN_CREDENTIALS') {
          cred = await _auth.createUserWithEmailAndPassword(
            email: firebaseEmail,
            password: firebasePassword,
          );
        } else {
          rethrow;
        }
      }

      // 5. Firebase displayName이 없으면 카카오 닉네임 저장
      if (cred.user?.displayName == null ||
          cred.user!.displayName!.isEmpty) {
        await cred.user?.updateDisplayName(nickname);
      }

      return cred;
    } catch (e) {
      if (e is AuthException) rethrow;
      // TODO: 배포 전 제거 - 디버그용 실제 오류 노출
      throw AuthException('카카오 오류: $e');
    }
  }

  // ── 네이버 로그인 ───────────────────────────────────────────
  // 네이버 SDK → Firebase email/password 방식으로 연결
  // ※ 네이버 개발자 콘솔에서 앱 등록 후 client_id/secret을 strings.xml에 설정 필요
  Future<UserCredential?> signInWithNaver() async {
    try {
      // 1. 네이버 로그인
      final result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.loggedOut) {
        return null; // 사용자가 취소
      }
      if (result.status == NaverLoginStatus.error) {
        throw AuthException('네이버 로그인 오류: ${result.errorMessage ?? '알 수 없는 오류'}');
      }

      // 2. 네이버 사용자 정보 (logIn 결과에 포함된 account 또는 getCurrentAccount 사용)
      final account =
          result.account ?? await FlutterNaverLogin.getCurrentAccount();
      final naverId = account.id ?? '';
      final nickname =
          (account.nickname?.isNotEmpty == true)
              ? account.nickname!
              : ((account.name?.isNotEmpty == true)
                  ? account.name!
                  : '네이버 사용자');

      // 3. Firebase 계정 구성
      final firebaseEmail = 'naver_$naverId@naver.cl.user';
      final firebasePassword = 'naver_${naverId}_cl2024!';

      // 4. Firebase 로그인 시도 → 없으면 계정 생성
      UserCredential cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(
          email: firebaseEmail,
          password: firebasePassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'INVALID_LOGIN_CREDENTIALS') {
          cred = await _auth.createUserWithEmailAndPassword(
            email: firebaseEmail,
            password: firebasePassword,
          );
        } else {
          rethrow;
        }
      }

      // 5. displayName 없으면 네이버 닉네임 저장
      if (cred.user?.displayName == null ||
          cred.user!.displayName!.isEmpty) {
        await cred.user?.updateDisplayName(nickname);
      }

      return cred;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('네이버 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  // ── 이메일/비밀번호 ─────────────────────────────────────────
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

  // ── 비밀번호 재설정 이메일 전송 ──────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }


  // ── 로그아웃 (모든 소셜 동시 처리) ──────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      FlutterNaverLogin.logOut(),
    ]);
    // 카카오 로그아웃 (오류 무시)
    try {
      await UserApi.instance.logout();
    } catch (_) {}
  }

  // ── 회원탈퇴 ─────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('로그인 상태가 아닙니다.');

    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    try {
      // 1. Firestore 이벤트 데이터 삭제
      final eventsSnap =
          await db.collection('users').doc(uid).collection('events').get();
      final batch = db.batch();
      for (final doc in eventsSnap.docs) {
        batch.delete(doc.reference);
      }
      // 2. Firestore 프로필 데이터 삭제
      batch.delete(
          db.collection('users').doc(uid).collection('profile').doc('data'));
      await batch.commit();

      // 3. 소셜 로그아웃
      await Future.wait([
        _googleSignIn.signOut(),
        FlutterNaverLogin.logOut(),
      ]);
      try {
        await UserApi.instance.logout();
      } catch (_) {}

      // 4. Firebase Auth 계정 삭제
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
            '보안을 위해 재로그인이 필요합니다.\n로그아웃 후 다시 로그인하여 탈퇴를 진행해주세요.');
      }
      throw AuthException('계정 삭제에 실패했습니다: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('계정 삭제 중 오류가 발생했습니다.');
    }
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
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return '이메일 또는 비밀번호가 올바르지 않습니다';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요';
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
