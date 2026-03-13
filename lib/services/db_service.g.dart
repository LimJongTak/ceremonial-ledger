// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_service.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$EventsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _dateMeta = const VerificationMeta('date');
@override
late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>('date', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
static const VerificationMeta _personNameMeta = const VerificationMeta('personName');
@override
late final GeneratedColumn<String> personName = GeneratedColumn<String>('person_name', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _relationMeta = const VerificationMeta('relation');
@override
late final GeneratedColumnWithTypeConverter<RelationType, String> relation = GeneratedColumn<String>('relation', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true).withConverter<RelationType>($EventsTable.$converterrelation);
static const VerificationMeta _ceremonyTypeMeta = const VerificationMeta('ceremonyType');
@override
late final GeneratedColumnWithTypeConverter<CeremonyType, String> ceremonyType = GeneratedColumn<String>('ceremony_type', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true).withConverter<CeremonyType>($EventsTable.$converterceremonyType);
static const VerificationMeta _amountMeta = const VerificationMeta('amount');
@override
late final GeneratedColumn<int> amount = GeneratedColumn<int>('amount', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
static const VerificationMeta _eventTypeMeta = const VerificationMeta('eventType');
@override
late final GeneratedColumnWithTypeConverter<EventType, String> eventType = GeneratedColumn<String>('event_type', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true).withConverter<EventType>($EventsTable.$convertereventType);
static const VerificationMeta _memoMeta = const VerificationMeta('memo');
@override
late final GeneratedColumn<String> memo = GeneratedColumn<String>('memo', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
@override
late final GeneratedColumn<String> userId = GeneratedColumn<String>('user_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
static const VerificationMeta _photoPathMeta = const VerificationMeta('photoPath');
@override
late final GeneratedColumn<String> photoPath = GeneratedColumn<String>('photo_path', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _isRecurringMeta = const VerificationMeta('isRecurring');
@override
late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>('is_recurring', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_recurring" IN (0, 1))'), defaultValue: const Constant(false));
static const VerificationMeta _photoPathsMeta = const VerificationMeta('photoPaths');
@override
late final GeneratedColumn<String> photoPaths = GeneratedColumn<String>('photo_paths', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, date, personName, relation, ceremonyType, amount, eventType, memo, userId, photoPath, isRecurring, photoPaths];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'events';
@override
VerificationContext validateIntegrity(Insertable<Event> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('date')) {
context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));} else if (isInserting) {
context.missing(_dateMeta);
}
if (data.containsKey('person_name')) {
context.handle(_personNameMeta, personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta));} else if (isInserting) {
context.missing(_personNameMeta);
}
context.handle(_relationMeta, const VerificationResult.success());context.handle(_ceremonyTypeMeta, const VerificationResult.success());if (data.containsKey('amount')) {
context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));} else if (isInserting) {
context.missing(_amountMeta);
}
context.handle(_eventTypeMeta, const VerificationResult.success());if (data.containsKey('memo')) {
context.handle(_memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));}if (data.containsKey('user_id')) {
context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));} else if (isInserting) {
context.missing(_userIdMeta);
}
if (data.containsKey('photo_path')) {
context.handle(_photoPathMeta, photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));}if (data.containsKey('is_recurring')) {
context.handle(_isRecurringMeta, isRecurring.isAcceptableOrUnknown(data['is_recurring']!, _isRecurringMeta));}if (data.containsKey('photo_paths')) {
context.handle(_photoPathsMeta, photoPaths.isAcceptableOrUnknown(data['photo_paths']!, _photoPathsMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Event map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Event(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!, personName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}person_name'])!, relation: $EventsTable.$converterrelation.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}relation'])!), ceremonyType: $EventsTable.$converterceremonyType.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ceremony_type'])!), amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!, eventType: $EventsTable.$convertereventType.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_type'])!), memo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}memo']), userId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}user_id'])!, photoPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}photo_path']), isRecurring: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!, photoPaths: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}photo_paths']), );
}
@override
$EventsTable createAlias(String alias) {
return $EventsTable(attachedDatabase, alias);}static JsonTypeConverter2<RelationType,String,String> $converterrelation = const EnumNameConverter<RelationType>(RelationType.values);static JsonTypeConverter2<CeremonyType,String,String> $converterceremonyType = const EnumNameConverter<CeremonyType>(CeremonyType.values);static JsonTypeConverter2<EventType,String,String> $convertereventType = const EnumNameConverter<EventType>(EventType.values);}class Event extends DataClass implements Insertable<Event> 
{
final int id;
final DateTime date;
final String personName;
final RelationType relation;
final CeremonyType ceremonyType;
final int amount;
final EventType eventType;
final String? memo;
final String userId;
final String? photoPath;
final bool isRecurring;
final String? photoPaths;
const Event({required this.id, required this.date, required this.personName, required this.relation, required this.ceremonyType, required this.amount, required this.eventType, this.memo, required this.userId, this.photoPath, required this.isRecurring, this.photoPaths});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
map['date'] = Variable<DateTime>(date);
map['person_name'] = Variable<String>(personName);
{map['relation'] = Variable<String>($EventsTable.$converterrelation.toSql(relation));
}{map['ceremony_type'] = Variable<String>($EventsTable.$converterceremonyType.toSql(ceremonyType));
}map['amount'] = Variable<int>(amount);
{map['event_type'] = Variable<String>($EventsTable.$convertereventType.toSql(eventType));
}if (!nullToAbsent || memo != null){map['memo'] = Variable<String>(memo);
}map['user_id'] = Variable<String>(userId);
if (!nullToAbsent || photoPath != null){map['photo_path'] = Variable<String>(photoPath);
}map['is_recurring'] = Variable<bool>(isRecurring);
if (!nullToAbsent || photoPaths != null){map['photo_paths'] = Variable<String>(photoPaths);
}return map; 
}
EventsCompanion toCompanion(bool nullToAbsent) {
return EventsCompanion(id: Value(id),date: Value(date),personName: Value(personName),relation: Value(relation),ceremonyType: Value(ceremonyType),amount: Value(amount),eventType: Value(eventType),memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),userId: Value(userId),photoPath: photoPath == null && nullToAbsent ? const Value.absent() : Value(photoPath),isRecurring: Value(isRecurring),photoPaths: photoPaths == null && nullToAbsent ? const Value.absent() : Value(photoPaths),);
}
factory Event.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Event(id: serializer.fromJson<int>(json['id']),date: serializer.fromJson<DateTime>(json['date']),personName: serializer.fromJson<String>(json['personName']),relation: $EventsTable.$converterrelation.fromJson(serializer.fromJson<String>(json['relation'])),ceremonyType: $EventsTable.$converterceremonyType.fromJson(serializer.fromJson<String>(json['ceremonyType'])),amount: serializer.fromJson<int>(json['amount']),eventType: $EventsTable.$convertereventType.fromJson(serializer.fromJson<String>(json['eventType'])),memo: serializer.fromJson<String?>(json['memo']),userId: serializer.fromJson<String>(json['userId']),photoPath: serializer.fromJson<String?>(json['photoPath']),isRecurring: serializer.fromJson<bool>(json['isRecurring']),photoPaths: serializer.fromJson<String?>(json['photoPaths']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'date': serializer.toJson<DateTime>(date),'personName': serializer.toJson<String>(personName),'relation': serializer.toJson<String>($EventsTable.$converterrelation.toJson(relation)),'ceremonyType': serializer.toJson<String>($EventsTable.$converterceremonyType.toJson(ceremonyType)),'amount': serializer.toJson<int>(amount),'eventType': serializer.toJson<String>($EventsTable.$convertereventType.toJson(eventType)),'memo': serializer.toJson<String?>(memo),'userId': serializer.toJson<String>(userId),'photoPath': serializer.toJson<String?>(photoPath),'isRecurring': serializer.toJson<bool>(isRecurring),'photoPaths': serializer.toJson<String?>(photoPaths),};}Event copyWith({int? id,DateTime? date,String? personName,RelationType? relation,CeremonyType? ceremonyType,int? amount,EventType? eventType,Value<String?> memo = const Value.absent(),String? userId,Value<String?> photoPath = const Value.absent(),bool? isRecurring,Value<String?> photoPaths = const Value.absent()}) => Event(id: id ?? this.id,date: date ?? this.date,personName: personName ?? this.personName,relation: relation ?? this.relation,ceremonyType: ceremonyType ?? this.ceremonyType,amount: amount ?? this.amount,eventType: eventType ?? this.eventType,memo: memo.present ? memo.value : this.memo,userId: userId ?? this.userId,photoPath: photoPath.present ? photoPath.value : this.photoPath,isRecurring: isRecurring ?? this.isRecurring,photoPaths: photoPaths.present ? photoPaths.value : this.photoPaths,);Event copyWithCompanion(EventsCompanion data) {
return Event(
id: data.id.present ? data.id.value : this.id,date: data.date.present ? data.date.value : this.date,personName: data.personName.present ? data.personName.value : this.personName,relation: data.relation.present ? data.relation.value : this.relation,ceremonyType: data.ceremonyType.present ? data.ceremonyType.value : this.ceremonyType,amount: data.amount.present ? data.amount.value : this.amount,eventType: data.eventType.present ? data.eventType.value : this.eventType,memo: data.memo.present ? data.memo.value : this.memo,userId: data.userId.present ? data.userId.value : this.userId,photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,isRecurring: data.isRecurring.present ? data.isRecurring.value : this.isRecurring,photoPaths: data.photoPaths.present ? data.photoPaths.value : this.photoPaths,);
}
@override
String toString() {return (StringBuffer('Event(')..write('id: $id, ')..write('date: $date, ')..write('personName: $personName, ')..write('relation: $relation, ')..write('ceremonyType: $ceremonyType, ')..write('amount: $amount, ')..write('eventType: $eventType, ')..write('memo: $memo, ')..write('userId: $userId, ')..write('photoPath: $photoPath, ')..write('isRecurring: $isRecurring, ')..write('photoPaths: $photoPaths')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, date, personName, relation, ceremonyType, amount, eventType, memo, userId, photoPath, isRecurring, photoPaths);@override
bool operator ==(Object other) => identical(this, other) || (other is Event && other.id == this.id && other.date == this.date && other.personName == this.personName && other.relation == this.relation && other.ceremonyType == this.ceremonyType && other.amount == this.amount && other.eventType == this.eventType && other.memo == this.memo && other.userId == this.userId && other.photoPath == this.photoPath && other.isRecurring == this.isRecurring && other.photoPaths == this.photoPaths);
}class EventsCompanion extends UpdateCompanion<Event> {
final Value<int> id;
final Value<DateTime> date;
final Value<String> personName;
final Value<RelationType> relation;
final Value<CeremonyType> ceremonyType;
final Value<int> amount;
final Value<EventType> eventType;
final Value<String?> memo;
final Value<String> userId;
final Value<String?> photoPath;
final Value<bool> isRecurring;
final Value<String?> photoPaths;
const EventsCompanion({this.id = const Value.absent(),this.date = const Value.absent(),this.personName = const Value.absent(),this.relation = const Value.absent(),this.ceremonyType = const Value.absent(),this.amount = const Value.absent(),this.eventType = const Value.absent(),this.memo = const Value.absent(),this.userId = const Value.absent(),this.photoPath = const Value.absent(),this.isRecurring = const Value.absent(),this.photoPaths = const Value.absent(),});
EventsCompanion.insert({this.id = const Value.absent(),required DateTime date,required String personName,required RelationType relation,required CeremonyType ceremonyType,required int amount,required EventType eventType,this.memo = const Value.absent(),required String userId,this.photoPath = const Value.absent(),this.isRecurring = const Value.absent(),this.photoPaths = const Value.absent(),}): date = Value(date), personName = Value(personName), relation = Value(relation), ceremonyType = Value(ceremonyType), amount = Value(amount), eventType = Value(eventType), userId = Value(userId);
static Insertable<Event> custom({Expression<int>? id, 
Expression<DateTime>? date, 
Expression<String>? personName, 
Expression<String>? relation, 
Expression<String>? ceremonyType, 
Expression<int>? amount, 
Expression<String>? eventType, 
Expression<String>? memo, 
Expression<String>? userId, 
Expression<String>? photoPath, 
Expression<bool>? isRecurring, 
Expression<String>? photoPaths, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (date != null)'date': date,if (personName != null)'person_name': personName,if (relation != null)'relation': relation,if (ceremonyType != null)'ceremony_type': ceremonyType,if (amount != null)'amount': amount,if (eventType != null)'event_type': eventType,if (memo != null)'memo': memo,if (userId != null)'user_id': userId,if (photoPath != null)'photo_path': photoPath,if (isRecurring != null)'is_recurring': isRecurring,if (photoPaths != null)'photo_paths': photoPaths,});
}EventsCompanion copyWith({Value<int>? id, Value<DateTime>? date, Value<String>? personName, Value<RelationType>? relation, Value<CeremonyType>? ceremonyType, Value<int>? amount, Value<EventType>? eventType, Value<String?>? memo, Value<String>? userId, Value<String?>? photoPath, Value<bool>? isRecurring, Value<String?>? photoPaths}) {
return EventsCompanion(id: id ?? this.id,date: date ?? this.date,personName: personName ?? this.personName,relation: relation ?? this.relation,ceremonyType: ceremonyType ?? this.ceremonyType,amount: amount ?? this.amount,eventType: eventType ?? this.eventType,memo: memo ?? this.memo,userId: userId ?? this.userId,photoPath: photoPath ?? this.photoPath,isRecurring: isRecurring ?? this.isRecurring,photoPaths: photoPaths ?? this.photoPaths,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (date.present) {
map['date'] = Variable<DateTime>(date.value);}
if (personName.present) {
map['person_name'] = Variable<String>(personName.value);}
if (relation.present) {
map['relation'] = Variable<String>($EventsTable.$converterrelation.toSql(relation.value));}
if (ceremonyType.present) {
map['ceremony_type'] = Variable<String>($EventsTable.$converterceremonyType.toSql(ceremonyType.value));}
if (amount.present) {
map['amount'] = Variable<int>(amount.value);}
if (eventType.present) {
map['event_type'] = Variable<String>($EventsTable.$convertereventType.toSql(eventType.value));}
if (memo.present) {
map['memo'] = Variable<String>(memo.value);}
if (userId.present) {
map['user_id'] = Variable<String>(userId.value);}
if (photoPath.present) {
map['photo_path'] = Variable<String>(photoPath.value);}
if (isRecurring.present) {
map['is_recurring'] = Variable<bool>(isRecurring.value);}
if (photoPaths.present) {
map['photo_paths'] = Variable<String>(photoPaths.value);}
return map; 
}
@override
String toString() {return (StringBuffer('EventsCompanion(')..write('id: $id, ')..write('date: $date, ')..write('personName: $personName, ')..write('relation: $relation, ')..write('ceremonyType: $ceremonyType, ')..write('amount: $amount, ')..write('eventType: $eventType, ')..write('memo: $memo, ')..write('userId: $userId, ')..write('photoPath: $photoPath, ')..write('isRecurring: $isRecurring, ')..write('photoPaths: $photoPaths')..write(')')).toString();}
}
abstract class _$AppDatabase extends GeneratedDatabase{
_$AppDatabase(QueryExecutor e): super(e);
$AppDatabaseManager get managers => $AppDatabaseManager(this);
late final $EventsTable events = $EventsTable(this);
@override
Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [events];
}
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({Value<int> id,required DateTime date,required String personName,required RelationType relation,required CeremonyType ceremonyType,required int amount,required EventType eventType,Value<String?> memo,required String userId,Value<String?> photoPath,Value<bool> isRecurring,Value<String?> photoPaths,});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({Value<int> id,Value<DateTime> date,Value<String> personName,Value<RelationType> relation,Value<CeremonyType> ceremonyType,Value<int> amount,Value<EventType> eventType,Value<String?> memo,Value<String> userId,Value<String?> photoPath,Value<bool> isRecurring,Value<String?> photoPaths,});
class $$EventsTableFilterComposer extends Composer<
        _$AppDatabase,
        $EventsTable> {
        $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName,
      builder: (column) => 
      ColumnFilters(column));
      
          ColumnWithTypeConverterFilters<RelationType,RelationType,String> get relation => $composableBuilder(
      column: $table.relation,
      builder: (column) => 
      ColumnWithTypeConverterFilters(column));
      
          ColumnWithTypeConverterFilters<CeremonyType,CeremonyType,String> get ceremonyType => $composableBuilder(
      column: $table.ceremonyType,
      builder: (column) => 
      ColumnWithTypeConverterFilters(column));
      
ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount,
      builder: (column) => 
      ColumnFilters(column));
      
          ColumnWithTypeConverterFilters<EventType,EventType,String> get eventType => $composableBuilder(
      column: $table.eventType,
      builder: (column) => 
      ColumnWithTypeConverterFilters(column));
      
ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get photoPaths => $composableBuilder(
      column: $table.photoPaths,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$EventsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $EventsTable> {
        $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get relation => $composableBuilder(
      column: $table.relation,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get ceremonyType => $composableBuilder(
      column: $table.ceremonyType,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get photoPaths => $composableBuilder(
      column: $table.photoPaths,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$EventsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $EventsTable> {
        $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get date => $composableBuilder(
      column: $table.date,
      builder: (column) => column);
      
GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName,
      builder: (column) => column);
      
          GeneratedColumnWithTypeConverter<RelationType,String> get relation => $composableBuilder(
      column: $table.relation,
      builder: (column) => column);
      
          GeneratedColumnWithTypeConverter<CeremonyType,String> get ceremonyType => $composableBuilder(
      column: $table.ceremonyType,
      builder: (column) => column);
      
GeneratedColumn<int> get amount => $composableBuilder(
      column: $table.amount,
      builder: (column) => column);
      
          GeneratedColumnWithTypeConverter<EventType,String> get eventType => $composableBuilder(
      column: $table.eventType,
      builder: (column) => column);
      
GeneratedColumn<String> get memo => $composableBuilder(
      column: $table.memo,
      builder: (column) => column);
      
GeneratedColumn<String> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => column);
      
GeneratedColumn<String> get photoPath => $composableBuilder(
      column: $table.photoPath,
      builder: (column) => column);
      
GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring,
      builder: (column) => column);
      
GeneratedColumn<String> get photoPaths => $composableBuilder(
      column: $table.photoPaths,
      builder: (column) => column);
      
        }
      class $$EventsTableTableManager extends RootTableManager    <_$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event,BaseReferences<_$AppDatabase,$EventsTable,Event>),
    Event,
    PrefetchHooks Function()
    > {
    $$EventsTableTableManager(_$AppDatabase db, $EventsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$EventsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$EventsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$EventsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<DateTime> date = const Value.absent(),Value<String> personName = const Value.absent(),Value<RelationType> relation = const Value.absent(),Value<CeremonyType> ceremonyType = const Value.absent(),Value<int> amount = const Value.absent(),Value<EventType> eventType = const Value.absent(),Value<String?> memo = const Value.absent(),Value<String> userId = const Value.absent(),Value<String?> photoPath = const Value.absent(),Value<bool> isRecurring = const Value.absent(),Value<String?> photoPaths = const Value.absent(),})=> EventsCompanion(id: id,date: date,personName: personName,relation: relation,ceremonyType: ceremonyType,amount: amount,eventType: eventType,memo: memo,userId: userId,photoPath: photoPath,isRecurring: isRecurring,photoPaths: photoPaths,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),required DateTime date,required String personName,required RelationType relation,required CeremonyType ceremonyType,required int amount,required EventType eventType,Value<String?> memo = const Value.absent(),required String userId,Value<String?> photoPath = const Value.absent(),Value<bool> isRecurring = const Value.absent(),Value<String?> photoPaths = const Value.absent(),})=> EventsCompanion.insert(id: id,date: date,personName: personName,relation: relation,ceremonyType: ceremonyType,amount: amount,eventType: eventType,memo: memo,userId: userId,photoPath: photoPath,isRecurring: isRecurring,photoPaths: photoPaths,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$EventsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event,BaseReferences<_$AppDatabase,$EventsTable,Event>),
    Event,
    PrefetchHooks Function()
    >;class $AppDatabaseManager {
final _$AppDatabase _db;
$AppDatabaseManager(this._db);
$$EventsTableTableManager get events => $$EventsTableTableManager(_db, _db.events);
}
