import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../common/app_theme.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nicknameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 소셜 로그인 닉네임 미리 채우기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final displayName =
          ref.read(authStateProvider).value?.displayName ?? '';
      if (displayName.isNotEmpty && _nicknameCtrl.text.isEmpty) {
        _nicknameCtrl.text = displayName;
      }
    });
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (nickname.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임은 12자 이내로 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) return;

      // 로그인 방식 판별
      final email =
          ref.read(authStateProvider).value?.email ?? '';
      final loginType = email.contains('@kakao.cl.user')
          ? 'kakao'
          : email.contains('@naver.cl.user')
              ? 'naver'
              : email.isEmpty
                  ? 'google'
                  : 'email';

      final profile = UserProfile(
        uid: uid,
        nickname: nickname,
        realName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        loginType: loginType,
      );

      await ProfileService.instance.saveProfile(profile);
      // userProfileProvider가 자동으로 업데이트 → main.dart 라우팅이 MainNavScreen으로 이동
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppTheme.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Stack(
        children: [
          // 배경 장식
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.secondary.withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // 헤더
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradientPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '프로필 설정',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '앱에서 사용할 닉네임을 설정해주세요',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),

                  const SizedBox(height: 48),

                  // 닉네임 입력
                  _InputLabel(label: '닉네임', required: true),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameCtrl,
                    maxLength: 12,
                    decoration: const InputDecoration(
                      hintText: '예) 홍길동, 길동이',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      prefixIconColor: AppTheme.textSecondary,
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 이름 입력 (선택)
                  _InputLabel(label: '이름 (선택)', required: false),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: '실제 이름 (선택사항)',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      prefixIconColor: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 저장 버튼
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradientPrimary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _saving ? null : _save,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  '시작하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 로그아웃 링크
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.read(authNotifierProvider.notifier).signOut(),
                      child: const Text(
                        '다른 계정으로 로그인',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _InputLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*',
                style: TextStyle(color: AppTheme.expense, fontSize: 13)),
          ],
        ],
      );
}
