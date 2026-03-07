import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/auth_service.dart';
// TODO: OCR 기능 준비 중 - import '../calendar/ocr_register_screen.dart';
import '../export/excel_import_screen.dart';
import '../export/export_screen.dart';
import '../common/app_theme.dart';
import 'profile_edit_screen.dart';
import 'version_info_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final eventsAsync = ref.watch(allEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final fmt = NumberFormat('#,###');

    // 표시할 이름: Firestore 프로필 닉네임 > Firebase displayName > 이메일 앞
    final displayName = profile?.nickname ??
        user?.displayName ??
        user?.email?.split('@').first ??
        '사용자';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 프로필 헤더 ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.paddingOf(context).top + 20, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(children: [
                // 아바타 + 수정 버튼
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            width: 2),
                      ),
                      child: ClipOval(
                        child: user?.photoURL != null
                            ? Image.network(
                                user!.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    color: AppTheme.primary,
                                    size: 40),
                              )
                            : const Icon(Icons.person_rounded,
                                color: AppTheme.primary, size: 40),
                      ),
                    ),
                    // 수정 버튼
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileEditScreen())),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 20),

                // 총계 칩
                Row(children: [
                  Expanded(
                      child: _StatChip(
                          label: '총 수입',
                          value: '${fmt.format(totalIncome)}원',
                          color: AppTheme.income)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatChip(
                          label: '총 지출',
                          value: '${fmt.format(totalExpense)}원',
                          color: AppTheme.expense)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatChip(
                          label: '내역 수',
                          value: '${events.length}건',
                          color: AppTheme.gold)),
                ]),
              ]),
            ),
          ),

          // ── 메뉴 섹션 ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // 계정 관리
                _Section(
                  title: '계정 관리',
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppTheme.primary,
                      title: '프로필 수정',
                      subtitle: '닉네임, 이름 변경',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 데이터 관리
                _Section(
                  title: '데이터 관리',
                  children: [
                    // TODO: OCR 기능 준비 중 - 카메라 일괄 등록 메뉴
                    _MenuItem(
                      icon: Icons.table_view_outlined,
                      iconColor: AppTheme.secondary,
                      title: '엑셀로 일괄 등록',
                      subtitle: '양식 다운로드 후 업로드',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExcelImportScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.upload_file_outlined,
                      iconColor: AppTheme.accent,
                      title: '내보내기',
                      subtitle: 'PDF / 엑셀로 저장',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExportScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 앱 정보
                _Section(
                  title: '앱 정보',
                  children: [
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppTheme.primary,
                      title: '버전 정보',
                      subtitle: 'v1.0.0',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VersionInfoScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      iconColor: AppTheme.secondary,
                      title: '이용약관',
                      subtitle: '서비스 이용약관 보기',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LegalScreen(type: LegalType.terms))),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppTheme.accent,
                      title: '개인정보처리방침',
                      subtitle: '개인정보 수집 및 이용 안내',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LegalScreen(type: LegalType.privacy))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 로그아웃
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('로그아웃'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(
                          color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 회원탈퇴
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppTheme.expense.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '회원탈퇴',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.textSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('회원탈퇴',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.expense)),
        content: const Text(
          '탈퇴하면 모든 경조사 데이터가 영구적으로 삭제됩니다.\n정말 탈퇴하시겠습니까?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('계정을 삭제하는 중...'),
          ],
        ),
      ),
    );

    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기
        final msg = e is AuthException ? e.message : '계정 삭제 중 오류가 발생했습니다.';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('오류',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: Text(msg),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: List.generate(children.length, (i) {
                return Column(
                  children: [
                    children[i],
                    if (i < children.length - 1)
                      const Divider(
                          height: 1,
                          indent: 68,
                          endIndent: 0,
                          color: Color(0xFFF1F5F9)),
                  ],
                );
              }),
            ),
          ),
        ],
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ]),
        ),
      );
}
