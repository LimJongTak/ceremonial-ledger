<div align="center">

# 오고가고
### 스마트한 경조사 장부

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-006AC1?style=for-the-badge)](https://riverpod.dev)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=for-the-badge)](./CHANGELOG.md)

<br>

> **소중한 마음을 잊지 않고 기록하세요.**
> 복잡한 경조사비 관리를 직관적이고 스마트하게 해결하는 모바일 장부 앱입니다.

</div>

<br>

---

## 📱 주요 화면

| 로그인 | 홈 | 캘린더 | 장부 | 통계 | 프로필 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="assets/images/screenshot_login.png" width="130"> | <img src="assets/images/screenshot_home.png" width="130"> | <img src="assets/images/screenshot_calendar.png" width="130"> | <img src="assets/images/screenshot_ledger.png" width="130"> | <img src="assets/images/screenshot_stats.png" width="130"> | <img src="assets/images/screenshot_profile.png" width="130"> |

<br>

---

## ✨ 핵심 기능

### 🔐 인증 & 프로필

| 기능 | 설명 |
|---|---|
| **소셜 로그인** | Google · 카카오 · 네이버 · 이메일/비밀번호 로그인 지원 |
| **프로필 설정** | 최초 로그인 시 닉네임·이름 설정 화면 자동 진입 |
| **프로필 수정** | 닉네임·이름 편집 후 Firestore 및 Firebase Auth 동기화 |
| **회원탈퇴** | Firestore 전체 데이터 삭제 후 Firebase Auth 계정 영구 삭제 |

### 📝 경조사 내역 관리

| 기능 | 설명 |
|---|---|
| **상세 기록** | 날짜 · 이름 · 관계(가족/친구/직장 등) · 경조사 종류(결혼/장례/생일 등) · 금액 · 메모 |
| **수입/지출 구분** | 받은 마음(수입)과 보낸 마음(지출)을 명확히 분리 |
| **실시간 동기화** | Cloud Firestore 기반 실시간 데이터 스트리밍 |
| **로컬 캐시** | Drift(SQLite) 로컬 DB로 오프라인에서도 데이터 접근 가능 |

### 📊 대시보드 & 통계

| 기능 | 설명 |
|---|---|
| **홈 요약** | 최근 내역 및 이번 달 수입·지출 요약 |
| **캘린더 뷰** | 월별 달력에서 경조사 일정 한눈에 파악 |
| **통계 화면** | 연·월별 수입/지출 합계, 건수, 차트 |
| **장부 목록** | 전체 내역 검색 및 필터링 |
| **홈 위젯** | 홈 화면 위젯에서 주요 통계 바로 확인 |

### ⚡ 자동화 도구

| 기능 | 설명 |
|---|---|
| **엑셀 일괄 등록** | 제공된 양식에 맞춰 작성한 `.xlsx` 파일을 앱으로 업로드하면 한 번에 등록 |
| **데이터 내보내기** | PDF 보고서 또는 Excel 파일로 변환·저장·공유 |
| **OCR 스캔** | *(준비 중)* Google ML Kit 기반 봉투·청첩장 텍스트 자동 인식 |

### 🔔 알림

| 기능 | 설명 |
|---|---|
| **경조사 알림** | 예정된 경조사 날짜에 맞춰 로컬 푸시 알림 |
| **알림 목록** | 예약된 알림 목록 확인 및 관리 |

### ⚙️ 앱 설정

| 기능 | 설명 |
|---|---|
| **버전 정보** | 버전별 업데이트 날짜 및 변경사항 확인 |
| **이용약관** | 서비스 이용약관 인앱 표시 |
| **개인정보처리방침** | 개인정보 수집·이용 안내 인앱 표시 |

<br>

---

## 🛠️ 기술 스택

```
┌─────────────────────────────────────────────────────┐
│                    Frontend (Flutter)                │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │ Riverpod │  │ Drift DB │  │   Pretendard Font  │ │
│  │  State   │  │  SQLite  │  │   Material 3 UI    │ │
│  └──────────┘  └──────────┘  └────────────────────┘ │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                  Backend (Firebase)                  │
│  ┌──────────────┐        ┌────────────────────────┐  │
│  │ Firebase Auth│        │   Cloud Firestore      │  │
│  │  · Google    │        │  users/{uid}/          │  │
│  │  · 카카오    │        │    profile/data        │  │
│  │  · 네이버    │        │    events/{eventId}    │  │
│  │  · 이메일    │        └────────────────────────┘  │
│  └──────────────┘                                    │
└─────────────────────────────────────────────────────┘
```

### 주요 패키지

| 분류 | 패키지 | 버전 |
|---|---|---|
| **상태 관리** | flutter_riverpod | ^2.4.9 |
| **인증** | firebase_auth | ^4.15.3 |
| **인증** | google_sign_in | ^6.2.1 |
| **인증** | kakao_flutter_sdk_user | ^1.9.1 |
| **인증** | flutter_naver_login | ^2.1.1 |
| **DB (클라우드)** | cloud_firestore | ^4.14.0 |
| **DB (로컬)** | drift + drift_flutter | ^2.14.1 |
| **캘린더** | table_calendar | ^3.0.9 |
| **엑셀** | excel | ^4.0.6 |
| **PDF** | pdf + printing | ^3.10.8 |
| **OCR** | google_mlkit_text_recognition | ^0.13.0 |
| **알림** | flutter_local_notifications | ^17.2.2 |
| **홈 위젯** | home_widget | ^0.6.0 |
| **파일** | file_picker + open_file | ^8.1.2 |
| **공유** | share_plus | ^7.2.1 |

<br>

---

## 📂 프로젝트 구조

```
lib/
├── main.dart                     # 앱 진입점, Firebase 초기화, 라우팅
├── firebase_options.dart         # Firebase 프로젝트 설정
│
├── models/
│   ├── event_model.dart          # 경조사 내역 모델 (EventModel, RelationType, CeremonyType 등)
│   └── user_profile.dart        # 사용자 프로필 모델 (UserProfile)
│
├── providers/
│   ├── auth_provider.dart        # 인증 상태 관리 (AuthNotifier, userProfileProvider)
│   └── event_provider.dart      # 이벤트 CRUD 및 통계 (EventNotifier, ledgerSummaryProvider)
│
├── services/
│   ├── auth_service.dart         # Firebase Auth + 소셜 로그인 + 회원탈퇴
│   ├── profile_service.dart      # Firestore 프로필 CRUD
│   ├── firestore_service.dart    # Firestore 이벤트 CRUD
│   ├── db_service.dart           # Drift 로컬 SQLite
│   ├── export_service.dart       # Excel/PDF 내보내기
│   ├── excel_template_service.dart # 엑셀 양식 생성
│   ├── pdf_report_service.dart   # PDF 보고서 생성
│   ├── notification_service.dart # 로컬 푸시 알림
│   └── home_widget_service.dart  # 홈 위젯 업데이트
│
└── views/
    ├── auth/
    │   ├── login_screen.dart         # 로그인 화면 (소셜 + 이메일)
    │   └── profile_setup_screen.dart # 최초 프로필 설정 화면
    ├── home/
    │   ├── main_nav_screen.dart      # 하단 네비게이션 (홈/캘린더/장부/통계/프로필)
    │   ├── home_screen.dart          # 홈 화면 (최근 내역, 월 요약)
    │   └── stats_screen.dart         # 통계 화면
    ├── calendar/
    │   ├── calendar_screen.dart      # 캘린더 뷰
    │   ├── event_bottom_sheet.dart   # 내역 등록/수정 바텀시트
    │   └── ocr_register_screen.dart  # OCR 스캔 화면 (준비 중)
    ├── ledger/
    │   └── ledger_screen.dart        # 장부 목록 화면
    ├── search/
    │   └── search_screen.dart        # 검색 화면
    ├── export/
    │   ├── excel_import_screen.dart  # 엑셀 일괄 등록
    │   └── export_screen.dart        # 데이터 내보내기
    ├── notifications/
    │   └── notification_screen.dart  # 알림 목록
    ├── profile/
    │   ├── profile_screen.dart       # 프로필 탭 메인
    │   ├── profile_edit_screen.dart  # 닉네임/이름 수정
    │   ├── version_info_screen.dart  # 버전 정보 & 업데이트 내역
    │   └── legal_screen.dart         # 이용약관 / 개인정보처리방침
    └── common/
        └── app_theme.dart            # 앱 전체 테마 (색상, 폰트, 컴포넌트)
```

<br>

---

## 🚀 시작하기

### 사전 요구사항

- Flutter 3.x 이상
- Dart 3.x 이상
- Firebase 프로젝트 (Auth + Firestore)
- 카카오 개발자 앱 등록
- 네이버 개발자 앱 등록

---

### 1. 저장소 클론

```bash
git clone https://github.com/LimJongTak/ceremonial-ledger.git
cd ceremonial-ledger
```

### 2. 패키지 설치

```bash
flutter pub get
```

### 3. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. Android 앱 등록 → `google-services.json`을 `android/app/`에 배치
3. **Authentication** → 로그인 방법 → 이메일/비밀번호 · Google 활성화
4. **Firestore Database** 생성 후 아래 보안 규칙 적용

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                        && request.auth.uid == userId;
    }
  }
}
```

### 4. 소셜 로그인 설정

#### 카카오 로그인
1. [카카오 개발자 콘솔](https://developers.kakao.com) → 앱 생성
2. **앱 키 → 네이티브 앱 키** 복사 → `lib/main.dart`의 `KakaoSdk.init(appKey: ...)` 값 교체
3. **플랫폼 → Android** → 패키지명 `com.yourcompany.ceremonial_ledger`, 키 해시 등록
4. **카카오 로그인 → 활성화** 및 **Redirect URI** 설정: `kakao{네이티브앱키}://oauth`

```bash
# 디버그 키 해시 생성 (Windows)
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
```

#### 네이버 로그인
1. [네이버 개발자 센터](https://developers.naver.com) → 앱 등록 → **네이버 로그인** API 선택
2. Android 패키지명 등록 후 `Client ID` / `Client Secret` 확인
3. `android/app/src/main/res/values/strings.xml` 값 교체:

```xml
<resources>
  <string name="naver_client_id">여기에_클라이언트_ID</string>
  <string name="naver_client_secret">여기에_클라이언트_시크릿</string>
  <string name="naver_client_name">오고가고</string>
</resources>
```

### 5. 앱 실행

```bash
flutter run
```

### 6. (선택) 앱 아이콘 및 스플래시 재생성

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

<br>

---

## 🗺️ 앱 플로우

```
앱 실행
  └─ 스플래시
       └─ 로그인 여부 확인
            ├─ 미로그인 → 로그인 화면 (Google / 카카오 / 네이버 / 이메일)
            │                └─ 최초 로그인 → 프로필 설정 화면 (닉네임 입력)
            └─ 로그인됨 → 메인 화면 (하단 탭 네비게이션)
                              ├─ 홈       : 최근 내역 + 월 요약
                              ├─ 캘린더   : 달력 뷰 + 내역 등록/수정
                              ├─ 장부     : 전체 목록 + 검색
                              ├─ 통계     : 월별/연별 차트
                              └─ 프로필   : 계정 관리 + 데이터 관리 + 앱 정보
```

<br>

---

## 📋 버전 내역

| 버전 | 출시일 | 주요 변경사항 |
|---|---|---|
| **v1.0.0** | 2025년 3월 | 최초 출시 — 경조사 기록, 소셜 로그인, 캘린더, 통계, 엑셀 가져오기/내보내기, 홈 위젯, 알림, 프로필 수정, 회원탈퇴 |

<br>

---

## 🔒 보안 및 개인정보

- 모든 사용자 데이터는 Firebase Auth UID 기반으로 격리 저장
- Firestore 보안 규칙으로 본인 데이터만 접근 가능
- 소셜 로그인 시 외부 서버에 비밀번호 미전송
- 회원탈퇴 시 Firestore 데이터 즉시 일괄 삭제

<br>

---

## 📄 라이선스

이 프로젝트는 비공개(Private) 프로젝트입니다.
무단 복제 및 배포를 금지합니다.

---

<div align="center">

**오고가고** · ⓒ 2025 All rights reserved.

</div>
