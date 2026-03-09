import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event_model.dart';
import '../models/notification_settings.dart';
import 'notification_settings_service.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── 초기화 ─────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('알림 탭: ${details.payload}');
      },
    );

    // Android 권한 요청
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('✅ NotificationService 초기화 완료');
  }

  // ── 알림 채널 ────────────────────────────────────────────────
  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'ceremonial_ledger_channel',
        '경조사 알림',
        channelDescription: '다가오는 경조사 일정 알림',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2563EB),
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

  // ── 예정 이벤트 알림 스케줄 ──────────────────────────────────
  /// [days]가 null이면 저장된 사용자 설정에서 읽어옴
  Future<void> scheduleEventNotifications(EventModel event,
      {List<int>? days}) async {
    if (!_initialized) await initialize();

    final notifDays = days ??
        (await NotificationSettingsService.instance.load()).notificationDays;

    final now = DateTime.now();

    for (final daysBefore in notifDays) {
      final DateTime scheduledDate;
      final String title;
      final String body;

      if (daysBefore == 0) {
        // D-day 당일 오전 9시
        scheduledDate =
            DateTime(event.date.year, event.date.month, event.date.day, 9, 0);
        title = '🎉 오늘! | ${event.ceremonyType.emoji} ${event.personName}';
        body = '오늘은 ${event.personName}님의 ${event.ceremonyType.label} 날입니다!';
      } else {
        scheduledDate = event.date.subtract(Duration(days: daysBefore));
        title =
            '📅 D-$daysBefore | ${event.ceremonyType.emoji} ${event.personName}';
        body = daysBefore == 1
            ? '${event.personName}님의 ${event.ceremonyType.label}이 내일입니다! 준비하셨나요?'
            : '${event.personName}님의 ${event.ceremonyType.label}이 $daysBefore일 후입니다!';
      }

      if (scheduledDate.isAfter(now)) {
        await _scheduleNotification(
          id: _notifId(event, daysBefore),
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: 'event_${event.id}',
        );
        debugPrint('📅 D-$daysBefore 알림 예약: ${event.personName} - $scheduledDate');
      }
    }
  }

  // ── 이벤트 알림 취소 ──────────────────────────────────────────
  Future<void> cancelEventNotifications(EventModel event) async {
    // 현재 스킴: 모든 가능한 알림일 취소
    for (final day in NotificationSettings.availableDays) {
      await _plugin.cancel(_notifId(event, day));
    }
    // 이전 스킴 호환: D-7, D-1, D-0
    final oldBase = (event.id.abs() % 100000) * 10;
    await _plugin.cancel(oldBase + 7);
    await _plugin.cancel(oldBase + 1);
    await _plugin.cancel(oldBase);
  }

  // ── 모든 알림 취소 ────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── 예약된 알림 목록 ──────────────────────────────────────────
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ── 이벤트 목록으로 전체 재스케줄 ──────────────────────────────
  Future<void> rescheduleAll(List<EventModel> events,
      {List<int>? days}) async {
    await cancelAll();
    final notifDays = days ??
        (await NotificationSettingsService.instance.load()).notificationDays;
    final upcoming = events.where(
      (e) => e.date.isAfter(DateTime.now()) && e.amount >= 0,
    );
    for (final event in upcoming) {
      await scheduleEventNotifications(event, days: notifDays);
    }
    debugPrint(
        '✅ ${upcoming.length}개 이벤트 알림 재스케줄 완료 (days: $notifDays)');
  }

  // ── 즉시 테스트 알림 ──────────────────────────────────────────
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();
    await _plugin.show(
      9999,
      '🔔 알림 테스트',
      '경조사 장부 알림이 정상적으로 작동합니다!',
      NotificationDetails(android: _androidDetails),
    );
  }

  // ── private 헬퍼 ──────────────────────────────────────────────
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tzDate = tz.TZDateTime.from(
      DateTime(
          scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0),
      tz.local,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  int _notifId(EventModel event, int daysBefore) {
    // 고유 ID: (eventId % 10000) * 100 + daysBefore (0~99)
    return (event.id.abs() % 10000) * 100 + daysBefore.clamp(0, 99);
  }
}
