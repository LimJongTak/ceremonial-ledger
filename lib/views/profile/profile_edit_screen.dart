import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../common/app_theme.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _realNameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).valueOrNull;
    _nicknameCtrl = TextEditingController(text: profile?.nickname ?? '');
    _realNameCtrl = TextEditingController(text: profile?.realName ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _realNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) return;

      final currentProfile = ref.read(userProfileProvider).valueOrNull;
      final updatedProfile = UserProfile(
        uid: uid,
        nickname: _nicknameCtrl.text.trim(),
        realName: _realNameCtrl.text.trim().isNotEmpty
            ? _realNameCtrl.text.trim()
            : null,
        loginType: currentProfile?.loginType ?? 'email',
      );

      await ProfileService.instance.saveProfile(updatedProfile);

      // Firebase Auth displayName도 동기화
      final user = ref.read(authStateProvider).value;
      if (user != null && user.displayName != updatedProfile.nickname) {
        await user.updateDisplayName(updatedProfile.nickname);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 수정되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary))
                  : const Text('저장',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.primary)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 아바타
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.gradientPrimary,
                ),
                child: ClipOval(
                  child: user?.photoURL != null
                      ? Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 44),
                        )
                      : const Icon(Icons.person_rounded,
                          color: Colors.white, size: 44),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 32),

            // 닉네임
            _buildLabel('닉네임 *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                hintText: '사용할 닉네임을 입력하세요',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요';
                if (v.trim().length > 20) return '닉네임은 20자 이하여야 합니다';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // 이름 (선택)
            _buildLabel('이름 (선택)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _realNameCtrl,
              decoration: const InputDecoration(
                hintText: '실명을 입력하세요 (선택사항)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            const Text(
              '이름은 경조사 내보내기 보고서 등에 사용됩니다.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary),
      );
}
