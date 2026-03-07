import 'package:flutter/material.dart';
import '../common/app_theme.dart';

enum LegalType { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == LegalType.terms;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(isTerms ? '이용약관' : '개인정보처리방침'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: isTerms ? const _TermsContent() : const _PrivacyContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('오고가고 서비스 이용약관'),
        _buildDate('시행일: 2025년 3월 1일'),
        const SizedBox(height: 24),
        _buildSection('제1조 (목적)', '''
본 약관은 오고가고(이하 "회사")가 제공하는 경조사 장부 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.
'''),
        _buildSection('제2조 (서비스 이용)', '''
이용자는 본 약관에 동의하고 서비스에 가입함으로써 서비스를 이용할 수 있습니다. 이용자는 서비스를 통해 경조사 내역을 기록하고 관리할 수 있습니다.
'''),
        _buildSection('제3조 (계정 관리)', '''
이용자는 자신의 계정 정보를 안전하게 관리할 책임이 있습니다. 계정 정보 유출로 인한 손해에 대해 회사는 책임을 지지 않습니다.
'''),
        _buildSection('제4조 (서비스 변경 및 중단)', '''
회사는 서비스의 내용을 변경하거나 중단할 수 있으며, 이 경우 사전에 이용자에게 공지합니다.
'''),
        _buildSection('제5조 (면책조항)', '''
회사는 이용자가 서비스를 통해 얻은 정보에 대한 정확성, 신뢰성에 대해 보증하지 않습니다. 이용자 귀책 사유로 발생한 손해에 대해 회사는 책임을 지지 않습니다.
'''),
        _buildSection('제6조 (분쟁 해결)', '''
본 약관에 관한 분쟁은 대한민국 법률에 따르며, 분쟁 발생 시 민사소송법상의 관할 법원을 관할 법원으로 합니다.
'''),
      ],
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('개인정보처리방침'),
        _buildDate('시행일: 2025년 3월 1일'),
        const SizedBox(height: 24),
        _buildSection('1. 수집하는 개인정보 항목', '''
회사는 서비스 제공을 위해 다음의 개인정보를 수집합니다.

• 필수 수집 항목: 이메일 주소, 닉네임
• 소셜 로그인 시: 소셜 서비스 계정 정보(프로필 사진 포함)
• 서비스 이용 시: 경조사 기록 데이터(입력하신 정보)
'''),
        _buildSection('2. 개인정보의 수집 및 이용 목적', '''
• 서비스 회원 가입 및 관리
• 서비스 제공 및 개선
• 고객 문의 응대
'''),
        _buildSection('3. 개인정보의 보유 및 이용 기간', '''
회원 탈퇴 시까지 보유합니다. 단, 관련 법령에 의해 보존이 필요한 경우 해당 기간 동안 보존합니다.

• 회원 탈퇴 시: 즉시 삭제
'''),
        _buildSection('4. 개인정보의 제3자 제공', '''
회사는 이용자의 개인정보를 원칙적으로 외부에 제공하지 않습니다. 단, 이용자의 동의가 있거나 법령에 의한 경우는 예외로 합니다.
'''),
        _buildSection('5. 개인정보의 파기', '''
수집 목적이 달성된 개인정보는 재생이 불가능한 방법으로 즉시 파기합니다.

• 전자적 파일 형태: 복원 불가능한 방법으로 영구 삭제
'''),
        _buildSection('6. 이용자의 권리', '''
이용자는 언제든지 다음과 같은 권리를 행사할 수 있습니다.

• 개인정보 조회, 수정, 삭제 요청
• 서비스 내 프로필 수정 기능을 통해 직접 수정 가능
• 회원 탈퇴를 통한 전체 데이터 삭제
'''),
        _buildSection('7. 개인정보 보호 책임자', '''
개인정보 처리에 관한 문의사항은 앱 내 고객센터를 이용해 주세요.
'''),
      ],
    );
  }
}

Widget _buildHeader(String title) => Text(
      title,
      style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5),
    );

Widget _buildDate(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    );

Widget _buildSection(String title, String content) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              content.trim(),
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.7),
            ),
          ),
        ],
      ),
    );
