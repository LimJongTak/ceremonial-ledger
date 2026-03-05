# 오고가고 (OgoGago) - 스마트한 경조사 장부

<p align="center">
  <img src="assets/images/app_logo.png" width="120" alt="App Logo" style="border-radius: 20px;">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/State_Management-Riverpod-blue" alt="Riverpod">
</p>

<h3 align="center">
  <b>소중한 마음을 잊지 않고 기록하세요.</b><br>
  복잡한 경조사비 관리를 직관적이고 스마트하게 해결하는 모바일 장부 앱입니다.
</h3>

<br>

## 📱 주요 화면 (Screenshots)

| 스플래시 (Splash) | 캘린더 (Calendar) | 프로필 & 통계 (Profile) |
|:---:|:---:|:---:|
| <img src="assets/images/splash.png" width="200"> | <img src="assets/images/screenshot_calendar.png" width="200"> | <img src="assets/images/screenshot_profile.png" width="200"> |

<br>

## ✨ 핵심 기능 (Key Features)

### 1. 📝 체계적인 내역 관리
- **상세 기록**: 날짜, 이름, 관계(가족, 친구 등), 경조사 종류(결혼, 부고 등), 금액, 메모 등을 상세히 기록합니다.
- **수입/지출 구분**: 받은 마음(수입)과 보낸 마음(지출)을 명확히 구분하여 관리합니다.

### 2. 📊 직관적인 대시보드
- **월별 캘린더**: 달력 뷰를 통해 언제 어떤 경조사가 있었는지 한눈에 파악할 수 있습니다.
- **실시간 통계**: 전체 기간 및 월별 총 수입, 총 지출, 내역 건수를 자동으로 집계하여 보여줍니다.

### 3. ⚡️ 강력한 자동화 도구
- **OCR 카메라 스캔**: 봉투나 청첩장을 카메라로 촬영하면 텍스트를 인식하여 자동으로 내역을 입력합니다. (Google ML Kit 활용)
- **엑셀 일괄 등록**: PC에서 작성한 엑셀 파일을 앱으로 불러와 수백 건의 데이터를 한 번에 등록할 수 있습니다.
- **데이터 내보내기**: 앱에 저장된 데이터를 PDF 또는 Excel 파일로 변환하여 백업하거나 공유할 수 있습니다.

### 4. 🎨 사용자 편의성
- **홈 위젯**: 앱을 실행하지 않아도 홈 화면에서 주요 통계를 확인할 수 있습니다.
- **직관적인 UI**: 누구나 쉽게 사용할 수 있는 깔끔하고 현대적인 디자인을 제공합니다.

<br>

## 🛠️ 기술 스택 (Tech Stack)

이 프로젝트는 유지보수성과 확장성을 고려하여 최신 Flutter 기술 스택을 기반으로 개발되었습니다.

- **Framework**: Flutter (Dart)
- **Architecture**: MVVM (Model-View-ViewModel) Pattern
- **State Management**: Riverpod (flutter_riverpod)
- **Key Libraries**:
  - `google_ml_kit`: 온디바이스 머신러닝 기반 텍스트 인식 (OCR)
  - `excel`: 엑셀 파일(.xlsx) 생성 및 파싱
  - `intl`: 다국어 지원 및 날짜/숫자 포맷팅
  - `file_picker` & `open_file`: 파일 시스템 접근 및 관리

<br>

## 📂 프로젝트 구조 (Project Structure)

```
lib/
├── common/          # 공통 UI 컴포넌트 및 테마 (AppTheme)
├── models/          # 데이터 모델 (EventModel, ExcelEntry 등)
├── providers/       # Riverpod 상태 관리 (AuthProvider, EventProvider)
├── services/        # 비즈니스 로직 및 외부 서비스 (ExcelService, OCRService)
├── views/           # UI 화면 구성
│   ├── calendar/    # 캘린더 및 메인 화면
│   ├── profile/     # 프로필 및 설정 화면
│   └── export/      # 엑셀 가져오기/내보내기 화면
└── main.dart        # 앱 진입점
```

<br>

## 🚀 시작하기 (Getting Started)

1. **저장소 클론 (Clone Repository)**
   ```bash
   git clone https://github.com/your-username/ceremonial_ledger.git
   ```
2. **패키지 설치 (Install Dependencies)**
   ```bash
   flutter pub get
   ```
3. **앱 실행 (Run App)**
   ```bash
   flutter run
   ```
