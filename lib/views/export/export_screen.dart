import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/pdf_report_service.dart';
import '../common/app_theme.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  bool _isGenerating = false;
  int _pendingNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final list = await NotificationService.instance.getPendingNotifications();
    if (mounted) setState(() => _pendingNotifCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final user = ref.watch(authStateProvider).value;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? '사용자';

    final years = _getYears(events);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 헤더
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.paddingOf(context).top + 20, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('내보내기 & 알림',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                  ]),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── PDF 보고서 ──────────────────────────────
                _SectionCard(
                  title: 'PDF 결산 보고서',
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: const Color(0xFFEF4444),
                  child: Column(children: [
                    // 연도 선택
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NavBtn(
                          icon: Icons.chevron_left,
                          onTap: years.isNotEmpty && years.first < _selectedYear
                              ? () => setState(() => _selectedYear--)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Text('$_selectedYear년',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(width: 20),
                        _NavBtn(
                          icon: Icons.chevron_right,
                          onTap: _selectedYear < DateTime.now().year
                              ? () => setState(() => _selectedYear++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 월 선택
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MonthChip(
                          label: '전체',
                          isActive: _selectedMonth == null,
                          onTap: () => setState(() => _selectedMonth = null),
                        ),
                        ...List.generate(
                            12,
                            (i) => _MonthChip(
                                  label: '${i + 1}월',
                                  isActive: _selectedMonth == i + 1,
                                  onTap: () =>
                                      setState(() => _selectedMonth = i + 1),
                                )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 미리보기 & 공유 버튼
                    Row(children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.preview_outlined,
                          label: '미리보기',
                          color: AppTheme.primary,
                          isLoading: false,
                          onTap: () => _previewPdf(events, userName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.share_outlined,
                          label: 'PDF 공유',
                          color: const Color(0xFFEF4444),
                          isLoading: _isGenerating,
                          onTap: () => _sharePdf(events, userName),
                        ),
                      ),
                    ]),

                    // 통계 미리보기
                    const SizedBox(height: 12),
                    _PdfPreviewStats(
                      events: events,
                      year: _selectedYear,
                      month: _selectedMonth,
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── 알림 설정 ──────────────────────────────
                _SectionCard(
                  title: '경조사 알림',
                  icon: Icons.notifications_outlined,
                  iconColor: AppTheme.gold,
                  child: Column(children: [
                    // 예약된 알림 수
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule_outlined,
                              size: 18, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('예약된 알림',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                              Text('$_pendingNotifCount개 알림이 예약됨',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              size: 18, color: AppTheme.primary),
                          onPressed: _loadPendingCount,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // 알림 정보
                    const _InfoRow(
                        icon: Icons.alarm_outlined, text: 'D-30: 30일 전 오전 9시 알림'),
                    const _InfoRow(
                        icon: Icons.alarm_outlined, text: 'D-7: 7일 전 오전 9시 알림'),
                    const _InfoRow(
                        icon: Icons.alarm_outlined, text: 'D-3: 3일 전 오전 9시 알림'),
                    const _InfoRow(
                        icon: Icons.alarm_outlined, text: 'D-1: 하루 전 오전 9시 알림'),
                    const _InfoRow(
                        icon: Icons.alarm_outlined, text: 'D-Day: 당일 오전 9시 알림'),

                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.refresh_outlined,
                          label: '알림 재설정',
                          color: AppTheme.primary,
                          isLoading: false,
                          onTap: () => _rescheduleAll(events),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.notifications_active_outlined,
                          label: '테스트 알림',
                          color: AppTheme.gold,
                          isLoading: false,
                          onTap: () => _testNotification(),
                        ),
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getYears(List<dynamic> events) {
    if (events.isEmpty) return [DateTime.now().year];
    final years = events.map((e) => e.date.year as int).toSet().toList();
    years.sort();
    return years;
  }

  Future<void> _previewPdf(events, String userName) async {
    try {
      await PdfReportService.instance.previewPdf(
        context: context,
        events: events,
        year: _selectedYear,
        month: _selectedMonth,
        userName: userName,
      );
    } catch (e) {
      if (mounted) {
        _showSnack('PDF 생성 실패: $e', isError: true);
      }
    }
  }

  Future<void> _sharePdf(events, String userName) async {
    setState(() => _isGenerating = true);
    try {
      await PdfReportService.instance.generateAndShare(
        events: events,
        year: _selectedYear,
        month: _selectedMonth,
        userName: userName,
      );
    } catch (e) {
      if (mounted) _showSnack('PDF 생성 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _rescheduleAll(events) async {
    await NotificationService.instance.rescheduleAll(events);
    await _loadPendingCount();
    if (mounted) _showSnack('✅ 알림이 재설정되었습니다');
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.showTestNotification();
    if (mounted) _showSnack('🔔 테스트 알림을 보냈습니다');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.expense : AppTheme.income,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── 위젯들 ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3)),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap != null
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20,
              color: onTap != null ? AppTheme.primary : Colors.grey[300]),
        ),
      );
}

class _MonthChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _MonthChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textSecondary)),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.isLoading,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: color))))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 14, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      );
}

class _PdfPreviewStats extends StatelessWidget {
  final List<dynamic> events; // ← dynamic으로 변경
  final int year;
  final int? month;
  const _PdfPreviewStats(
      {required this.events, required this.year, this.month});

  @override
  Widget build(BuildContext context) {
    final filtered = month != null
        ? events
            .where((e) => e.date.year == year && e.date.month == month)
            .toList()
        : events.where((e) => e.date.year == year).toList();

    final income = filtered
        .where((e) => e.isIncome)
        .fold<int>(0, (s, e) => s + (e.amount as int));
    final expense = filtered
        .where((e) => !e.isIncome)
        .fold<int>(0, (s, e) => s + (e.amount as int));
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatMini(
              label: '내역',
              value: '${filtered.length}건',
              color: AppTheme.primary),
          _StatMini(
              label: '수입',
              value: '${fmt.format(income)}원',
              color: AppTheme.income),
          _StatMini(
              label: '지출',
              value: '${fmt.format(expense)}원',
              color: AppTheme.expense),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatMini(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]);
}
