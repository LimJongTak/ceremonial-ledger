const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

// 경조사 종류 레이블 (EventModel.CeremonyType 순서와 일치)
const CEREMONY_LABELS = ['결혼', '부고', '돌', '생일', '졸업', '집들이', '승진', '기타'];

/**
 * 가족 공유 컬렉션에 새 이벤트가 추가되면
 * 등록자를 제외한 나머지 가족 구성원에게 FCM 푸시 알림 전송
 */
exports.notifyFamilyOnNewEvent = onDocumentCreated(
  'families/{familyId}/events/{eventId}',
  async (event) => {
    const db = getFirestore();
    const data = event.data.data();

    if (!data) return;

    const familyId = event.params.familyId;
    const creatorId = data.userId;

    // 1. 가족 문서에서 멤버 목록과 이름 맵 가져오기
    const familyDoc = await db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return;

    const familyData = familyDoc.data();
    const memberIds = familyData.memberIds || [];
    const memberNames = familyData.memberNames || {};

    // 등록자가 없거나 멤버가 1명이면 알림 불필요
    if (memberIds.length <= 1) return;

    // 2. 등록자 이름 확인
    const creatorName = memberNames[creatorId] || '멤버';

    // 3. 경조사 종류 텍스트
    const ceremonyIndex = typeof data.ceremonyType === 'number' ? data.ceremonyType : -1;
    const ceremonyLabel =
      ceremonyIndex >= 0 && ceremonyIndex < CEREMONY_LABELS.length
        ? CEREMONY_LABELS[ceremonyIndex]
        : '경조사';

    // 4. 등록자를 제외한 멤버들의 FCM 토큰 수집
    const otherMemberIds = memberIds.filter((uid) => uid !== creatorId);
    const tokenDocs = await Promise.all(
      otherMemberIds.map((uid) => db.collection('users').doc(uid).get()),
    );

    const tokens = tokenDocs
      .map((doc) => (doc.exists ? doc.data().fcmToken : null))
      .filter((token) => typeof token === 'string' && token.length > 0);

    if (tokens.length === 0) return;

    // 5. FCM 멀티캐스트 전송
    const multicastMessage = {
      notification: {
        title: '오고가고',
        body: `${creatorName}님이 새 ${ceremonyLabel} 경조사를 등록했습니다`,
      },
      data: {
        familyId,
        eventId: event.params.eventId,
        type: 'family_event',
      },
      android: {
        notification: {
          channelId: 'family_events',
          priority: 'high',
        },
      },
      tokens,
    };

    const response = await getMessaging().sendEachForMulticast(multicastMessage);
    console.log(
      `[notifyFamilyOnNewEvent] 전송 완료: ${response.successCount}성공 / ${response.failureCount}실패`,
    );
  },
);
