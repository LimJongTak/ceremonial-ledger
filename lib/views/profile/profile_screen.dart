import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
// TODO: OCR 기능 준비 중 - import '../calendar/ocr_register_screen.dart';
import '../export/excel_import_screen.dart';
import '../export/export_screen.dart';
import '../common/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final eventsAsync = ref.watch(allEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.paddingOf(context).top + 20, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppTheme.gradientPrimary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(children: [
                // 아바타
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: ClipOval(
                    child: user?.photoURL != null
                        ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded,
                            color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? user?.email?.split('@').first ?? '사용자',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
                const SizedBox(height: 20),

                // 총계
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
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
                      iconColor: Colors.grey,
                      title: '버전',
                      subtitle: '1.0.0',
                      onTap: () {},
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
                      foregroundColor: AppTheme.expense,
                      side: BorderSide(
                          color: AppTheme.expense.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
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
            child: Column(children: children),
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
