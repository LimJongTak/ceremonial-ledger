class NotificationSettings {
  /// 기본 알림 일수 5개: D-30, D-14, D-7, D-1, D-day
  static const List<int> defaultDays = [30, 14, 7, 1, 0];

  /// 선택 가능한 모든 옵션
  static const List<int> availableDays = [60, 30, 14, 7, 3, 2, 1, 0];

  final List<int> notificationDays;

  const NotificationSettings({required this.notificationDays});

  factory NotificationSettings.defaults() =>
      const NotificationSettings(notificationDays: defaultDays);

  Map<String, dynamic> toJson() => {'days': notificationDays};

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        notificationDays: List<int>.from(json['days'] as List),
      );

  NotificationSettings copyWith({List<int>? notificationDays}) =>
      NotificationSettings(
        notificationDays: notificationDays ?? this.notificationDays,
      );
}
