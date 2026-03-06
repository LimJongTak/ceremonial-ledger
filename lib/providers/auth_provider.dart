import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// 현재 유저 프로필 실시간 스트림
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ProfileService.instance.watchProfile(uid);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _s;
  AuthNotifier(this._s) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _s.signInWithGoogle().then((c) => c?.user));
  }

  Future<void> signInWithKakao() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _s.signInWithKakao().then((c) => c?.user));
  }

  Future<void> signInWithNaver() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _s.signInWithNaver().then((c) => c?.user));
  }

  Future<void> signInWithEmail(String email, String pw) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _s.signInWithEmail(email, pw).then((c) => c.user));
  }

  Future<void> createAccount(String email, String pw) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _s.createAccount(email, pw).then((c) => c.user));
  }

  Future<void> signOut() async {
    await _s.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
