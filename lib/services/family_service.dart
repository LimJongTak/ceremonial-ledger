import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/family_model.dart';

class FamilyService {
  FamilyService._();
  static final instance = FamilyService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _families =>
      _db.collection('families');

  // ── 6자리 초대 코드 생성 ─────────────────────────────────────
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── 가족 그룹 생성 ───────────────────────────────────────────
  Future<FamilyModel> createFamily(
      String userId, String name, String displayName) async {
    final code = _generateCode();
    final ref = _families.doc();
    final family = FamilyModel(
      id: ref.id,
      name: name,
      ownerId: userId,
      inviteCode: code,
      memberIds: [userId],
      memberNames: {userId: displayName},
      memberAliases: const {},
      createdAt: DateTime.now(),
    );
    await ref.set(family.toMap());
    return family;
  }

  // ── 초대 코드로 가족 참여 ────────────────────────────────────
  Future<FamilyModel> joinByCode(
      String userId, String code, String displayName) async {
    final snap = await _families
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) throw Exception('초대 코드가 올바르지 않습니다.');

    final doc = snap.docs.first;
    final family = FamilyModel.fromMap(doc.data(), doc.id);

    if (family.memberIds.contains(userId)) return family;
    if (family.memberIds.length >= 10) {
      throw Exception('최대 멤버 수(10명)를 초과했습니다.');
    }

    await doc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberNames.$userId': displayName,
    });

    return family.copyWith(memberIds: [...family.memberIds, userId]);
  }

  // ── 가족 나가기 ─────────────────────────────────────────────
  Future<void> leaveFamily(String userId, String familyId) async {
    final ref = _families.doc(familyId);
    await ref.update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberNames.$userId': FieldValue.delete(),
      'memberAliases.$userId': FieldValue.delete(),
    });

    // 남은 멤버 확인
    final snap = await ref.get();
    if (!snap.exists) return;
    final remaining =
        List<String>.from(snap.data()!['memberIds'] as List? ?? []);

    if (remaining.isEmpty) {
      await _deleteFamilyData(familyId);
    } else if (snap.data()!['ownerId'] == userId) {
      // 방장이 나가면 다음 멤버에게 방장 이전
      await ref.update({'ownerId': remaining.first});
    }
  }

  // ── 멤버 실제 이름 갱신 (본인 프로필 동기화용) ──────────────
  Future<void> updateMemberName(
      String familyId, String uid, String name) async {
    await _families.doc(familyId).update({
      'memberNames.$uid': name,
    });
  }

  // ── 멤버 별칭 설정 ───────────────────────────────────────────
  Future<void> updateMemberAlias(
      String familyId, String uid, String alias) async {
    await _families.doc(familyId).update({
      'memberAliases.$uid': alias,
    });
  }

  // ── 가족 그룹 해산 (방장 전용) ────────────────────────────────
  Future<void> deleteFamily(String familyId) async {
    await _deleteFamilyData(familyId);
  }

  Future<void> _deleteFamilyData(String familyId) async {
    final eventsSnap =
        await _families.doc(familyId).collection('events').get();
    final batch = _db.batch();
    for (final doc in eventsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_families.doc(familyId));
    await batch.commit();
  }

  // ── 현재 유저의 가족 실시간 감시 ────────────────────────────
  Stream<FamilyModel?> watchUserFamily(String userId) {
    return _families
        .where('memberIds', arrayContains: userId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : FamilyModel.fromMap(snap.docs.first.data(), snap.docs.first.id));
  }

  // ── 가족 공유 이벤트 실시간 감시 ────────────────────────────
  Stream<List<EventModel>> watchFamilyEvents(String familyId) {
    return _families
        .doc(familyId)
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return EventModel(
                id: doc.id.hashCode,
                date: (d['date'] as Timestamp).toDate(),
                personName: d['personName'] as String,
                relation: RelationType.values[d['relation'] as int],
                ceremonyType: CeremonyType.values[d['ceremonyType'] as int],
                amount: d['amount'] as int,
                eventType: EventType.values[d['eventType'] as int],
                memo: d['memo'] as String?,
                userId: d['userId'] as String,
                firestoreId: doc.id,
                photoPath: d['photoPath'] as String?,
              );
            }).toList());
  }

  // ── 가족 컬렉션에 이벤트 저장 ────────────────────────────────
  Future<String> saveFamilyEvent(
      EventModel event, String familyId, String userId) async {
    final col = _families.doc(familyId).collection('events');
    final data = {
      'date': Timestamp.fromDate(event.date),
      'personName': event.personName,
      'relation': event.relation.index,
      'ceremonyType': event.ceremonyType.index,
      'amount': event.amount,
      'eventType': event.eventType.index,
      'memo': event.memo,
      'userId': userId,
      'photoPath': event.photoPath,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (event.firestoreId != null) {
      await col.doc(event.firestoreId).set(data);
      return event.firestoreId!;
    } else {
      final ref = col.doc();
      await ref.set(data);
      return ref.id;
    }
  }

  // ── 가족 컬렉션에서 이벤트 삭제 ─────────────────────────────
  Future<void> deleteFamilyEvent(String familyId, String firestoreId) async {
    await _families
        .doc(familyId)
        .collection('events')
        .doc(firestoreId)
        .delete();
  }
}
