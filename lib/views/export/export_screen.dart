import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/pdf_report_service.dart';
import '../../services/excel_template_service.dart';
import '../common/app_theme.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // 기간 설정
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  String _quickPeriod = '올해';
  bool _showCustomDate = false;

  // 카테고리 필터 (빈 Set = 전체)
  final Set<CeremonyType> _selectedCategories = {};

  // 상태
  bool _isGeneratingPdf = false;
  bool _isExportingExcel = false;
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

  void _setQuickPeriod(String period, List<dynamic> events) {
    final now = DateTime.now();
    setState(() {
      _quickPeriod = period;
      _showCustomDate = period == '직접 설정';
      switch (period) {
        case '이번 달':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
        case '지난 3개월':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
        case '올해':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
        case '전체':
          if (events.isNotEmpty) {
            final dates = events.map((e) => e.date as DateTime).toList();
            dates.sort();
            _startDate =
                DateTime(dates.first.year, dates.first.month, dates.first.day);
            _endDate =
                DateTime(dates.last.year, dates.last.month, dates.last.day);
          } else {
            _startDate = DateTime(now.year, 1, 1);
            _endDate = now;
          }
        case '직접 설정':
          break;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = DateTime(2000);
    final last = DateTime(2099);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  List<CeremonyType>? get _categoriesParam =>
      _selectedCategories.isEmpty ? null : _selectedCategories.toList();

  List<dynamic> _filteredEvents(List<dynamic> events) {
    final s = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final e = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    var result =
        events.where((ev) => !ev.date.isBefore(s) && !ev.date.isAfter(e)).toList();
    if (_selectedCategories.isNotEmpty) {
      result = result
          .where((ev) => _selectedCategories.contains(ev.ceremonyType))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final user = ref.watch(authStateProvider).value;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? '사용자';
    final filtered = _filteredEvents(events);

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
              child: Row(children: [
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
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 필터 설정 ──────────────────────────────────
                _SectionCard(
                  title: '내보내기 필터',
                  icon: Icons.tune_rounded,
                  iconColor: AppTheme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 기간 선택
                      const Text('기간',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['이번 달', '지난 3개월', '올해', '전체', '직접 설정']
                            .map((p) => _FilterChip(
                                  label: p,
                                  isActive: _quickPeriod == p,
                                  onTap: () => _setQuickPeriod(p, events),
                                ))
                            .toList(),
                      ),

                      // 직접 설정 시 DatePicker
                      if (_showCustomDate) ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _DateBtn(
                              label: '시작일',
                              date: _startDate,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('~',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary)),
                          ),
                          Expanded(
                            child: _DateBtn(
                              label: '종료일',
                              date: _endDate,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ]),
                      ],

                      // 선택된 기간 표시
                      if (!_showCustomDate) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            const Icon(Icons.date_range_outlined,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('yyyy.MM.dd').format(_startDate)} ~ ${DateFormat('yyyy.MM.dd').format(_endDate)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary),
                            ),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 카테고리 선택
                      const Text('카테고리',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _FilterChip(
                            label: '전체',
                            isActive: _selectedCategories.isEmpty,
                            onTap: () =>
                                setState(() => _selectedCategories.clear()),
                          ),
                          ...CeremonyType.values.map((c) => _FilterChip(
                                label: '${c.emoji} ${c.label}',
                                isActive: _selectedCategories.contains(c),
                                onTap: () => setState(() {
                                  if (_selectedCategories.contains(c)) {
                                    _selectedCategories.remove(c);
                                  } else {
                                    _selectedCategories.add(c);
                                  }
                                }),
                              )),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 필터 결과 미리보기
                      _FilteredStats(events: filtered),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── PDF 보고서 ──────────────────────────────────
                _SectionCard(
                  title: 'PDF 결산 보고서',
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: const Color(0xFFEF4444),
                  child: Column(children: [
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
                          isLoading: _isGeneratingPdf,
                          onTap: () => _sharePdf(events, userName),
                        ),
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Excel 내보내기 ──────────────────────────────
                _SectionCard(
                  title: 'Excel 내보내기',
                  icon: Icons.table_chart_outlined,
                  iconColor: const Color(0xFF10B981),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '필터 조건이 적용된 데이터를 .xlsx 파일로 저장합니다',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600]),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _ActionBtn(
                        icon: Icons.download_outlined,
                        label: 'Excel 파일 저장 (${filtered.length}건)',
                        color: const Color(0xFF10B981),
                        isLoading: _isExportingExcel,
                        onTap: () => _exportExcel(events),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── 알림 설정 ──────────────────────────────────
                _SectionCard(
                  title: '경조사 알림',
                  icon: Icons.notifications_outlined,
                  iconColor: AppTheme.gold,
                  child: Column(children: [
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

  Future<void> _previewPdf(List<dynamic> events, String userName) async {
    try {
      await PdfReportService.instance.previewPdf(
        context: context,
        events: events.cast<EventModel>(),
        startDate: _startDate,
        endDate: _endDate,
        categories: _categoriesParam,
        userName: userName,
      );
    } catch (e) {
      if (mounted) _showSnack('PDF 생성 실패: $e', isError: true);
    }
  }

  Future<void> _sharePdf(List<dynamic> events, String userName) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.instance.generateAndShare(
        events: events.cast<EventModel>(),
        startDate: _startDate,
        endDate: _endDate,
        categories: _categoriesParam,
        userName: userName,
      );
    } catch (e) {
      if (mounted) _showSnack('PDF 생성 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _exportExcel(List<dynamic> events) async {
    setState(() => _isExportingExcel = true);
    try {
      final path = await ExcelTemplateService.instance.exportData(
        events: events.cast<EventModel>(),
        startDate: _startDate,
        endDate: _endDate,
        categories: _categoriesParam,
      );
      if (path != null) {
        if (mounted) {
          _showSnack('✅ Excel 파일 저장됨');
          await ExcelTemplateService.instance.openFile(path);
        }
      } else {
        if (mounted) _showSnack('Excel 저장 실패', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Excel 저장 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _rescheduleAll(List<dynamic> events) async {
    await NotificationService.instance.rescheduleAll(events.cast<EventModel>());
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
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
            border: Border.all(
              color:
                  isActive ? AppTheme.primary : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textSecondary)),
        ),
      );
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(DateFormat('yyyy.MM.dd').format(date),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ],
          ),
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

class _FilteredStats extends StatelessWidget {
  final List<dynamic> events;
  const _FilteredStats({required this.events});

  @override
  Widget build(BuildContext context) {
    final income = events
        .where((e) => e.isIncome)
        .fold<int>(0, (s, e) => s + (e.amount as int));
    final expense = events
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
              value: '${events.length}건',
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
