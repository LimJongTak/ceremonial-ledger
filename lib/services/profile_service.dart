import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('profile').doc('data');

  // 프로필 실시간 스트림
  Stream<UserProfile?> watchProfile(String uid) {
    return _ref(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!);
    });
  }

  // 프로필 저장
  Future<void> saveProfile(UserProfile profile) async {
    await _ref(profile.uid).set(profile.toMap());
  }

  // 프로필 단건 읽기 (다른 멤버 이름 동기화용)
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _ref(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  // 프로필 존재 여부 확인
  Future<bool> hasProfile(String uid) async {
    final doc = await _ref(uid).get();
    return doc.exists && doc.data() != null;
  }
}
