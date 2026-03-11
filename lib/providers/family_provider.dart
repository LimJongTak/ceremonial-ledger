import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_model.dart';
import '../services/family_service.dart';
import 'auth_provider.dart';

// 현재 유저의 가족 그룹 실시간 감시
final familyProvider = StreamProvider<FamilyModel?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return FamilyService.instance.watchUserFamily(uid);
});

// 가족 멤버 닉네임 맵 (비동기)
final familyMemberNicknamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final family = ref.watch(familyProvider).valueOrNull;
  if (family == null) return {};
  return FamilyService.instance.getMemberNicknames(family.memberIds);
});
