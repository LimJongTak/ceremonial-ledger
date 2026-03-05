import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/event_model.dart';

part 'db_service.g.dart';

@DriftDatabase(tables: [Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'ceremonial_ledger');
  }

  // 저장 / 수정
  Future<void> saveEvent(EventModel event) async {
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

  EventModel _rowToModel(Event row) {
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
    );
  }
}

// 싱글턴
final db = AppDatabase();
