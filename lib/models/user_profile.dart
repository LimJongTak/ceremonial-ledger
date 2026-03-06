class UserProfile {
  final String uid;
  final String nickname;
  final String? realName;
  final String loginType; // 'email', 'google', 'kakao', 'naver'

  const UserProfile({
    required this.uid,
    required this.nickname,
    this.realName,
    required this.loginType,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        nickname: map['nickname'] as String,
        realName: map['realName'] as String?,
        loginType: map['loginType'] as String? ?? 'email',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nickname': nickname,
        'realName': realName,
        'loginType': loginType,
      };

  UserProfile copyWith({
    String? nickname,
    String? realName,
    String? loginType,
  }) =>
      UserProfile(
        uid: uid,
        nickname: nickname ?? this.nickname,
        realName: realName ?? this.realName,
        loginType: loginType ?? this.loginType,
      );
}
