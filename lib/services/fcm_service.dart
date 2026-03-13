import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM 백그라운드 메시지 핸들러 (최상위 함수 필수)
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // 백그라운드/종료 상태: FCM이 알림을 자동으로 표시함
}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  // 가족 알림 전용 로컬 알림 채널
  static const _androidChannel = AndroidNotificationChannel(
    'family_events',
    '가족 그룹 알림',
    description: '가족 구성원이 새 경조사를 등록할 때 알림',
    importance: Importance.high,
  );
  static final _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Android 알림 채널 생성
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 알림 권한 요청 (Android 13+ / iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 포그라운드 메시지 처리 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 현재 로그인된 유저 토큰 저장 & 갱신 구독
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _saveToken(uid);
    }
    _fcm.onTokenRefresh.listen((token) async {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        await _storeToken(currentUid, token);
      }
    });

    // 인증 상태 변경 시 토큰 저장/삭제
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveToken(user.uid);
      }
    });
  }

  /// 로그인 후 수동으로 토큰 저장 (auth_provider에서 호출 가능)
  Future<void> saveToken(String uid) => _saveToken(uid);

  /// 로그아웃 시 토큰 삭제
  Future<void> deleteToken(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ── private ────────────────────────────────────────────────

  Future<void> _saveToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _storeToken(uid, token);
    } catch (_) {}
  }

  Future<void> _storeToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _handleForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _showLocalNotification(title: n.title ?? '오고가고', body: n.body ?? '');
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'family_events',
      '가족 그룹 알림',
      channelDescription: '가족 구성원이 새 경조사를 등록할 때 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
