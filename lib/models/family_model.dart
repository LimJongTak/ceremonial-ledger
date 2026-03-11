import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final List<String> memberIds;
  final Map<String, String> memberNames;   // uid → 실제 이름 (가입 시 자동 저장)
  final Map<String, String> memberAliases; // uid → 별칭 (멤버가 직접 설정)
  final DateTime createdAt;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.memberIds,
    this.memberNames = const {},
    this.memberAliases = const {},
    required this.createdAt,
  });

  factory FamilyModel.fromMap(Map<String, dynamic> map, String id) {
    Map<String, String> toStringMap(dynamic raw) {
      if (raw == null) return {};
      return Map<String, String>.from(
          (raw as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
    }

    return FamilyModel(
      id: id,
      name: map['name'] as String? ?? '가족 공유 장부',
      ownerId: map['ownerId'] as String,
      inviteCode: map['inviteCode'] as String,
      memberIds: List<String>.from(map['memberIds'] as List),
      memberNames: toStringMap(map['memberNames']),
      memberAliases: toStringMap(map['memberAliases']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'memberAliases': memberAliases,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// 별칭 > 이름 > '멤버' 순서로 표시 이름 반환
  String displayNameFor(String uid) {
    final alias = memberAliases[uid];
    if (alias != null && alias.isNotEmpty) return alias;
    final name = memberNames[uid];
    if (name != null && name.isNotEmpty) return name;
    return '멤버';
  }

  FamilyModel copyWith({
    String? name,
    String? ownerId,
    List<String>? memberIds,
    Map<String, String>? memberNames,
    Map<String, String>? memberAliases,
  }) =>
      FamilyModel(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        inviteCode: inviteCode,
        memberIds: memberIds ?? this.memberIds,
        memberNames: memberNames ?? this.memberNames,
        memberAliases: memberAliases ?? this.memberAliases,
        createdAt: createdAt,
      );
}
