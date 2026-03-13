import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event_model.dart';

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
  Future<void> scheduleEventNotifications(EventModel event) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();

    // D-30 알림
    final d30 = event.date.subtract(const Duration(days: 30));
    if (d30.isAfter(now)) {
      await _scheduleNotification(
        id: _notifId(event, 30),
        title: '📆 D-30 | ${event.ceremonyType.emoji} ${event.personName}',
        body: '${event.personName}님의 ${event.ceremonyType.label}이 30일 후입니다!',
        scheduledDate: d30,
        payload: 'event_${event.id}',
      );
      debugPrint('📆 D-30 알림 예약: ${event.personName} - $d30');
    }

    // D-7 알림
    final d7 = event.date.subtract(const Duration(days: 7));
    if (d7.isAfter(now)) {
      await _scheduleNotification(
        id: _notifId(event, 7),
        title: '📅 D-7 | ${event.ceremonyType.emoji} ${event.personName}',
        body: '${event.personName}님의 ${event.ceremonyType.label}이 7일 후입니다!',
        scheduledDate: d7,
        payload: 'event_${event.id}',
      );
      debugPrint('📅 D-7 알림 예약: ${event.personName} - $d7');
    }

    // D-3 알림
    final d3 = event.date.subtract(const Duration(days: 3));
    if (d3.isAfter(now)) {
      await _scheduleNotification(
        id: _notifId(event, 3),
        title: '⏰ D-3 | ${event.ceremonyType.emoji} ${event.personName}',
        body: '${event.personName}님의 ${event.ceremonyType.label}이 3일 후입니다! 준비하셨나요?',
        scheduledDate: d3,
        payload: 'event_${event.id}',
      );
      debugPrint('⏰ D-3 알림 예약: ${event.personName} - $d3');
    }

    // D-1 알림
    final d1 = event.date.subtract(const Duration(days: 1));
    if (d1.isAfter(now)) {
      await _scheduleNotification(
        id: _notifId(event, 1),
        title: '🔔 내일! | ${event.ceremonyType.emoji} ${event.personName}',
        body:
            '${event.personName}님의 ${event.ceremonyType.label}이 내일입니다! 준비하셨나요?',
        scheduledDate: d1,
        payload: 'event_${event.id}',
      );
      debugPrint('🔔 D-1 알림 예약: ${event.personName} - $d1');
    }

    // D-day 당일 오전 9시
    final dDay =
        DateTime(event.date.year, event.date.month, event.date.day, 9, 0);
    if (dDay.isAfter(now)) {
      await _scheduleNotification(
        id: _notifId(event, 0),
        title: '🎉 오늘! | ${event.ceremonyType.emoji} ${event.personName}',
        body: '오늘은 ${event.personName}님의 ${event.ceremonyType.label} 날입니다!',
        scheduledDate: dDay,
        payload: 'event_${event.id}',
      );
    }
  }

  // ── 매년 반복 알림 스케줄 (향후 5년) ─────────────────────────
  Future<void> scheduleRecurringNotifications(EventModel event) async {
    if (!_initialized) await initialize();
    final now = DateTime.now();
    final baseMonth = event.date.month;
    final baseDay = event.date.day;

    for (int offset = 0; offset <= 4; offset++) {
      final year = now.year + offset;
      // 윤년 예외 (2월 29일 → 2월 28일로)
      final maxDay = _daysInMonth(year, baseMonth);
      final day = baseDay > maxDay ? maxDay : baseDay;
      final occDate = DateTime(year, baseMonth, day);

      // 이미 지난 날짜 스킵
      if (!occDate.isAfter(now)) continue;

      // D-7
      final d7 = occDate.subtract(const Duration(days: 7));
      if (d7.isAfter(now)) {
        await _scheduleNotification(
          id: _recurringId(event, offset, 7),
          title: '🔁 D-7 | ${event.ceremonyType.emoji} ${event.personName}',
          body: '${event.personName}님의 ${event.ceremonyType.label}이 7일 후예요!',
          scheduledDate: d7,
          payload: 'recurring_${event.id}',
        );
      }

      // D-day
      final dDay = DateTime(year, baseMonth, day, 9, 0);
      if (dDay.isAfter(now)) {
        await _scheduleNotification(
          id: _recurringId(event, offset, 0),
          title: '🔁 오늘! | ${event.ceremonyType.emoji} ${event.personName}',
          body: '오늘은 ${event.personName}님의 ${event.ceremonyType.label}입니다!',
          scheduledDate: dDay,
          payload: 'recurring_${event.id}',
        );
      }
    }
    debugPrint('🔁 반복 알림 예약: ${event.personName} (5년치)');
  }

  // ── 반복 알림 취소 ────────────────────────────────────────────
  Future<void> cancelRecurringNotifications(EventModel event) async {
    for (int offset = 0; offset <= 4; offset++) {
      await _plugin.cancel(_recurringId(event, offset, 7));
      await _plugin.cancel(_recurringId(event, offset, 0));
    }
  }

  // ── 이벤트 알림 취소 ──────────────────────────────────────────
  Future<void> cancelEventNotifications(EventModel event) async {
    // 현재 ID 취소 (base * 100)
    await _plugin.cancel(_notifId(event, 30));
    await _plugin.cancel(_notifId(event, 7));
    await _plugin.cancel(_notifId(event, 3));
    await _plugin.cancel(_notifId(event, 1));
    await _plugin.cancel(_notifId(event, 0));
    // 반복 알림도 취소
    await cancelRecurringNotifications(event);
    // 이전 ID 취소 (base * 10, 하위 호환)
    final oldBase = (event.id.abs() % 100000) * 10;
    await _plugin.cancel(oldBase + 7);
    await _plugin.cancel(oldBase + 1);
    await _plugin.cancel(oldBase + 0);
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
  Future<void> rescheduleAll(List<EventModel> events) async {
    await cancelAll();
    int count = 0;
    for (final event in events) {
      if (event.isRecurring) {
        await scheduleRecurringNotifications(event);
        count++;
      } else if (event.date.isAfter(DateTime.now()) && event.amount >= 0) {
        await scheduleEventNotifications(event);
        count++;
      }
    }
    debugPrint('✅ $count개 이벤트 알림 재스케줄 완료');
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
    // 고유 ID: eventId * 100 + daysBefore (0, 1, 3, 7, 30)
    final base = (event.id.abs() % 100000) * 100;
    return base + daysBefore.clamp(0, 39);
  }

  // 반복 알림 ID: 200,000,000 + eventId * 100 + offset * 10 + (daysBefore==7 ? 1 : 0)
  int _recurringId(EventModel event, int yearOffset, int daysBefore) {
    final base = 200000000 + (event.id.abs() % 10000) * 100 + yearOffset * 10;
    return base + (daysBefore > 0 ? 1 : 0);
  }

  // 월별 최대 일수 계산
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
