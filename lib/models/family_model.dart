import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
  });

  factory FamilyModel.fromMap(Map<String, dynamic> map, String id) {
    return FamilyModel(
      id: id,
      name: map['name'] as String? ?? '가족 공유 장부',
      ownerId: map['ownerId'] as String,
      inviteCode: map['inviteCode'] as String,
      memberIds: List<String>.from(map['memberIds'] as List),
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
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FamilyModel copyWith({
    String? name,
    String? ownerId,
    List<String>? memberIds,
  }) =>
      FamilyModel(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        inviteCode: inviteCode,
        memberIds: memberIds ?? this.memberIds,
        createdAt: createdAt,
      );
}
