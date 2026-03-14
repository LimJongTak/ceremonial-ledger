import 'package:drift/drift.dart';

enum EventType { income, expense }

enum RelationType { family, relative, friend, colleague, neighbor, other }

enum CeremonyType {
  wedding,
  funeral,
  babyShower,
  birthday,
  graduation,
  houseWarming,
  promotion,
  other
}

extension EventTypeExt on EventType {
  String get label => this == EventType.income ? '수입' : '지출';
  String get description => this == EventType.income ? '받은 돈' : '보낸 돈';
}

extension RelationTypeExt on RelationType {
  String get label => ['가족', '친척', '친구', '직장', '이웃', '기타'][index];
}

extension CeremonyTypeExt on CeremonyType {
  String get label => ['결혼', '부고', '돌', '생일', '졸업', '집들이', '승진', '기타'][index];
  String get emoji => ['💍', '🕊️', '👶', '🎂', '🎓', '🏠', '🎉', '📝'][index];
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get personName => text()();
  TextColumn get relation => textEnum<RelationType>()();
  TextColumn get ceremonyType => textEnum<CeremonyType>()();
  IntColumn get amount => integer()();
  TextColumn get eventType => textEnum<EventType>()();
  TextColumn get memo => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get photoPath => text().nullable()(); // 첨부 사진 로컬 경로 (하위 호환)
  BoolColumn get isRecurring =>
      boolean().withDefault(const Constant(false))(); // 매년 반복 알림
  TextColumn get photoPaths =>
      text().nullable()(); // JSON 인코딩된 다중 사진 경로 목록
  TextColumn get location => text().nullable()(); // 행사 장소
}

class EventModel {
  final int id;
  final DateTime date;
  final String personName;
  final RelationType relation;
  final CeremonyType ceremonyType;
  final int amount;
  final EventType eventType;
  final String? memo;
  final String userId;
  final String? firestoreId;
  final List<String> photos; // 다중 사진 경로 목록
  final bool isRecurring; // 매년 반복 알림
  final String? location; // 행사 장소

  EventModel({
    required this.id,
    required this.date,
    required this.personName,
    required this.relation,
    required this.ceremonyType,
    required this.amount,
    required this.eventType,
    this.memo,
    required this.userId,
    this.firestoreId,
    this.photos = const [],
    this.isRecurring = false,
    this.location,
  });

  // 하위 호환: 첫 번째 사진 반환
  String? get photoPath => photos.isEmpty ? null : photos.first;

  EventModel copyWith({DateTime? date, String? location}) => EventModel(
        id: id,
        date: date ?? this.date,
        personName: personName,
        relation: relation,
        ceremonyType: ceremonyType,
        amount: amount,
        eventType: eventType,
        memo: memo,
        userId: userId,
        firestoreId: firestoreId,
        photos: photos,
        isRecurring: isRecurring,
        location: location ?? this.location,
      );

  bool get isIncome => eventType == EventType.income;

  String get formattedAmount {
    final sign = isIncome ? '+' : '-';
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$sign$formatted원';
  }
}

class LedgerSummary {
  final int totalIncome;
  final int totalExpense;
  final List<EventModel> events;

  const LedgerSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.events,
  });

  int get balance => totalIncome - totalExpense;

  factory LedgerSummary.fromEvents(List<EventModel> events) {
    return LedgerSummary(
      totalIncome:
          events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount),
      totalExpense:
          events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount),
      events: events,
    );
  }
}
