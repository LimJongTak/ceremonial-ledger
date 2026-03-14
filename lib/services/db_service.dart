import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/event_model.dart';

part 'db_service.g.dart';

@DriftDatabase(tables: [Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: photoPath 컬럼 추가
            await m.addColumn(events, events.photoPath);
          }
          if (from < 3) {
            // v3: isRecurring 컬럼 추가
            await m.addColumn(events, events.isRecurring);
          }
          if (from < 4) {
            // v4: photoPaths 컬럼 추가 (다중 사진)
            await m.addColumn(events, events.photoPaths);
          }
          if (from < 5) {
            // v5: location 컬럼 추가 (행사 장소)
            await m.addColumn(events, events.location);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'ceremonial_ledger');
  }

  // 저장 / 수정
  Future<void> saveEvent(EventModel event) async {
    final photosJson =
        event.photos.isEmpty ? null : jsonEncode(event.photos);
    await into(events).insertOnConflictUpdate(
      EventsCompanion(
        id: event.id == 0 ? const Value.absent() : Value(event.id),
        date: Value(event.date),
        personName: Value(event.personName),
        relation: Value(event.relation),
        ceremonyType: Value(event.ceremonyType),
        amount: Value(event.amount),
        eventType: Value(event.eventType),
        memo: Value(event.memo),
        userId: Value(event.userId),
        photoPath: Value(event.photoPath), // 하위 호환 (첫 번째 사진)
        isRecurring: Value(event.isRecurring),
        photoPaths: Value(photosJson),
        location: Value(event.location),
      ),
    );
  }

  // 스트림
  Stream<List<EventModel>> watchAllEvents(String userId) {
    return (select(events)
          ..where((e) => e.userId.equals(userId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  // 삭제
  Future<void> deleteEvent(int id) async {
    await (delete(events)..where((e) => e.id.equals(id))).go();
  }

  // 특정 유저의 모든 이벤트 삭제 (백업 복원 시 사용)
  Future<void> deleteAllEvents(String userId) async {
    await (delete(events)..where((e) => e.userId.equals(userId))).go();
  }

  EventModel _rowToModel(Event row) {
    List<String> photos = [];
    if (row.photoPaths != null && row.photoPaths!.isNotEmpty) {
      photos = (jsonDecode(row.photoPaths!) as List).cast<String>();
    } else if (row.photoPath != null) {
      photos = [row.photoPath!];
    }

    return EventModel(
      id: row.id,
      date: row.date,
      personName: row.personName,
      relation: row.relation,
      ceremonyType: row.ceremonyType,
      amount: row.amount,
      eventType: row.eventType,
      memo: row.memo,
      userId: row.userId,
      photos: photos,
      isRecurring: row.isRecurring,
      location: row.location,
    );
  }
}

// 싱글턴
final db = AppDatabase();
