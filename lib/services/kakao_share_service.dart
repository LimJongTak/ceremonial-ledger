import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';

// ── 카카오톡 공유 서비스 ─────────────────────────────────────
class KakaoShareService {
  KakaoShareService._();
  static final instance = KakaoShareService._();

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.yourcompany.ceremonial_ledger';

  // ── 행사 정보 카카오톡 공유 ───────────────────────────────
  Future<bool> shareEvent(EventModel event) async {
    final dateStr =
        '${event.date.year}년 ${event.date.month}월 ${event.date.day}일';
    final locationLine =
        event.location != null ? '\n📍 ${event.location}' : '';

    final text = '${event.ceremonyType.emoji} ${event.personName}님의 '
        '${event.ceremonyType.label}\n'
        '📅 $dateStr$locationLine';

    final template = TextTemplate(
      text: text,
      link: Link(
        webUrl: Uri.parse(_storeUrl),
        mobileWebUrl: Uri.parse(_storeUrl),
      ),
      buttonTitle: '오고가고 앱 보기',
    );

    return _send(template);
  }

  // ── 앱 친구 초대 ─────────────────────────────────────────
  Future<bool> shareAppInvite() async {
    final template = TextTemplate(
      text: '📒 오고가고 - 경조사 장부\n'
          '결혼식·장례식·돌잔치 등 경조사 내역을\n'
          '스마트하게 관리해보세요!\n\n'
          '친구와 함께 사용하면 더 편리해요 😊',
      link: Link(
        webUrl: Uri.parse(_storeUrl),
        mobileWebUrl: Uri.parse(_storeUrl),
      ),
      buttonTitle: '앱 설치하기',
    );

    return _send(template);
  }

  // ── 공통 전송 로직 ────────────────────────────────────────
  Future<bool> _send(TextTemplate template) async {
    try {
      final available =
          await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (available) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        final uri = await WebSharerClient.instance
            .makeDefaultUrl(template: template);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return true;
    } catch (e) {
      debugPrint('카카오톡 공유 오류: $e');
      return false;
    }
  }
}
