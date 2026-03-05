import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userEvents(String userId) =>
      _db.collection('users').doc(userId).collection('events');

  // 저장 / 수정
  Future<void> saveEvent(EventModel event, String userId) async {
    final data = {
      'date': Timestamp.fromDate(event.date),
      'personName': event.personName,
      'relation': event.relation.index,
      'ceremonyType': event.ceremonyType.index,
      'amount': event.amount,
      'eventType': event.eventType.index,
      'memo': event.memo,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (event.id == 0) {
      await _userEvents(userId).add(data);
    } else {
      await _userEvents(userId).doc(event.id.toString()).set(data);
    }
  }

  // 실시간 스트림
  Stream<List<EventModel>> watchEvents(String userId) {
    return _userEvents(userId)
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
                userId: userId,
                firestoreId: doc.id,
              );
            }).toList());
  }

  // 삭제
  Future<void> deleteEvent(String userId, String firestoreId) async {
    await _userEvents(userId).doc(firestoreId).delete();
  }

  // 로컬 DB → Firestore 마이그레이션
  Future<void> migrateLocalEvents(
      List<EventModel> events, String userId) async {
    final batch = _db.batch();
    for (final event in events) {
      final ref = _userEvents(userId).doc();
      batch.set(ref, {
        'date': Timestamp.fromDate(event.date),
        'personName': event.personName,
        'relation': event.relation.index,
        'ceremonyType': event.ceremonyType.index,
        'amount': event.amount,
        'eventType': event.eventType.index,
        'memo': event.memo,
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
