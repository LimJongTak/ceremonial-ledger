import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../common/app_theme.dart';
import '../person/person_history_screen.dart';
import '../profile/profile_stats_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (events) {
          final yearEvents =
              events.where((e) => e.date.year == _selectedYear).toList();
          return _StatsBody(
            events: yearEvents,
            allEvents: events,
            selectedYear: _selectedYear,
            onYearChanged: (y) => setState(() => _selectedYear = y),
            tab: _tab,
          );
        },
      ),
    );
  }
}

// ── 메인 바디 ─────────────────────────────────────────────────
class _StatsBody extends StatefulWidget {
  final List<EventModel> events;
  final List<EventModel> allEvents;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final TabController tab;

  const _StatsBody({
    required this.events,
    required this.allEvents,
    required this.selectedYear,
    required this.onYearChanged,
    required this.tab,
  });

  @override
  State<_StatsBody> createState() => _StatsBodyState();
}

class _StatsBodyState extends State<_StatsBody> {
  bool _sharing = false;

  Future<void> _shareStats() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // 공유 카드 다이얼로그 표시 후 캡처
      await showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => _ShareDialog(
          events: widget.events,
          selectedYear: widget.selectedYear,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final allEvents = widget.allEvents;
    final selectedYear = widget.selectedYear;
    final onYearChanged = widget.onYearChanged;
    final tab = widget.tab;
    // 월별 데이터
    final monthlyData = List.generate(12, (i) {
      final month = i + 1;
      final monthEvents = events.where((e) => e.date.month == month).toList();
      final income =
          monthEvents.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
      final expense = monthEvents
          .where((e) => !e.isIncome)
          .fold(0, (s, e) => s + e.amount);
      return _MonthData(month: month, income: income, expense: expense);
    });

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);

    // 경조사별
    final Map<CeremonyType, int> byCategory = {};
    for (final e in events) {
      byCategory[e.ceremonyType] =
          (byCategory[e.ceremonyType] ?? 0) + e.amount;
    }
    final sortedCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 관계별
    final Map<RelationType, int> byRelation = {};
    for (final e in events) {
      byRelation[e.relation] = (byRelation[e.relation] ?? 0) + e.amount;
    }
    final sortedRels = byRelation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final fmt = NumberFormat('#,###');
    final total = totalIncome + totalExpense;

    // 연도 목록 (트렌드 차트용)
    final years = allEvents.map((e) => e.date.year).toSet().toList()..sort();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 헤더 ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.paddingOf(context).top + 20, 24, 24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('통계',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    GestureDetector(
                      onTap: _shareStats,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _sharing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary))
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ios_share_rounded,
                                      size: 15, color: AppTheme.primary),
                                  SizedBox(width: 5),
                                  Text('공유',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _YearBtn(
                      icon: Icons.chevron_left,
                      onTap: () => onYearChanged(selectedYear - 1)),
                  const SizedBox(width: 20),
                  Text('$selectedYear년',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 20),
                  _YearBtn(
                      icon: Icons.chevron_right,
                      onTap: selectedYear < DateTime.now().year
                          ? () => onYearChanged(selectedYear + 1)
                          : null),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _YearSummaryCard(
                          label: '총 수입',
                          value: '${fmt.format(totalIncome)}원',
                          icon: Icons.arrow_downward_rounded,
                          color: AppTheme.income,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileStatsScreen(
                                      type: StatsType.income))))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _YearSummaryCard(
                          label: '총 지출',
                          value: '${fmt.format(totalExpense)}원',
                          icon: Icons.arrow_upward_rounded,
                          color: AppTheme.expense,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileStatsScreen(
                                      type: StatsType.expense))))),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: '📊  통계'),
                      Tab(text: '📋  장부'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 통계 탭 ───────────────────────────────────────────
        if (tab.index == 0) ...[
          // 1. 월별 수입/지출 바 차트
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _ChartCard(
                title: '월별 수입/지출',
                child: _MonthlyBarChart(monthlyData: monthlyData),
              ),
            ),
          ),

          // 2. 연도별 트렌드 라인 차트 (2년 이상 데이터가 있을 때만)
          if (years.length >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ChartCard(
                  title: '연도별 트렌드',
                  child: _YearTrendChart(allEvents: allEvents, years: years),
                ),
              ),
            ),

          // 3. 관계별 파이 차트
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _ChartCard(
                title: '관계별 현황',
                child: sortedRels.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: Text('데이터 없음',
                                style: TextStyle(
                                    color: AppTheme.textSecondary))))
                    : _RelationPieChart(sortedRels: sortedRels),
              ),
            ),
          ),

          // 4. 경조사별 프로그레스 바
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: _ChartCard(
                title: '경조사별',
                child: sortedCats.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: Text('데이터 없음',
                                style: TextStyle(
                                    color: AppTheme.textSecondary))))
                    : Column(
                        children: sortedCats
                            .map((e) => _CategoryBar(
                                  emoji: e.key.emoji,
                                  label: e.key.label,
                                  amount: e.value,
                                  total: total == 0 ? 1 : total,
                                  color: AppTheme.primary,
                                ))
                            .toList(),
                      ),
              ),
            ),
          ),
        ],

        // ── 장부 탭 ───────────────────────────────────────────
        if (tab.index == 1) ...[
          if (events.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('이 연도의 내역이 없어요',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final sorted = [...events]
                      ..sort((a, b) => b.date.compareTo(a.date));
                    return _StatsLedgerItem(event: sorted[i]);
                  },
                  childCount: events.length,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── 섹션 카드 컨테이너 ────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

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
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

// ── 1. 월별 수입/지출 바 차트 ─────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthData> monthlyData;
  const _MonthlyBarChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlyData.fold(0, (max, d) {
      final m = d.income > d.expense ? d.income : d.expense;
      return m > max ? m : max;
    });
    final yMax = maxVal == 0 ? 100000.0 : maxVal * 1.3;
    final fmt = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _Legend(color: AppTheme.income, label: '수입'),
          const SizedBox(width: 16),
          _Legend(color: AppTheme.expense, label: '지출'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yMax,
              barGroups: monthlyData.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: d.income.toDouble(),
                      color: AppTheme.income,
                      width: 7,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: d.expense.toDouble(),
                      color: AppTheme.expense,
                      width: 7,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                  barsSpace: 2,
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt() + 1}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: yMax / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      final inMan = (value / 10000).round();
                      return Text('${inMan}만',
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.textSecondary));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yMax / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade800,
                  tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final amount = rod.toY.toInt();
                    if (amount == 0) return null;
                    final label = rodIndex == 0 ? '수입' : '지출';
                    return BarTooltipItem(
                      '$label\n${fmt.format(amount)}원',
                      TextStyle(
                        color: rodIndex == 0
                            ? AppTheme.income
                            : AppTheme.expense,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 2. 연도별 트렌드 라인 차트 ──────────────────────────────────
class _YearTrendChart extends StatelessWidget {
  final List<EventModel> allEvents;
  final List<int> years;
  const _YearTrendChart({required this.allEvents, required this.years});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    final incomeSpots = years.asMap().entries.map((entry) {
      final year = entry.value;
      final total = allEvents
          .where((e) => e.date.year == year && e.isIncome)
          .fold(0, (s, e) => s + e.amount);
      return FlSpot(entry.key.toDouble(), total.toDouble());
    }).toList();

    final expenseSpots = years.asMap().entries.map((entry) {
      final year = entry.value;
      final total = allEvents
          .where((e) => e.date.year == year && !e.isIncome)
          .fold(0, (s, e) => s + e.amount);
      return FlSpot(entry.key.toDouble(), total.toDouble());
    }).toList();

    final allValues = [...incomeSpots, ...expenseSpots].map((s) => s.y);
    final maxY = allValues.isEmpty
        ? 100000.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _Legend(color: AppTheme.income, label: '수입'),
          const SizedBox(width: 16),
          _Legend(color: AppTheme.expense, label: '지출'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (years.length - 1).toDouble(),
              minY: 0,
              maxY: maxY == 0 ? 100000 : maxY,
              lineBarsData: [
                // 수입 라인
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: years.length > 2,
                  color: AppTheme.income,
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.income,
                            strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.income.withValues(alpha: 0.08),
                  ),
                ),
                // 지출 라인
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: years.length > 2,
                  color: AppTheme.expense,
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.expense,
                            strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.expense.withValues(alpha: 0.08),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= years.length) {
                        return const SizedBox.shrink();
                      }
                      return Text('${years[idx]}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      final inMan = (value / 10000).round();
                      return Text('${inMan}만',
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.textSecondary));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade800,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      final yearIdx = spot.x.toInt();
                      final yearLabel = yearIdx < years.length
                          ? '${years[yearIdx]}년 '
                          : '';
                      return LineTooltipItem(
                        '$yearLabel${isIncome ? "수입" : "지출"}\n${fmt.format(spot.y.toInt())}원',
                        TextStyle(
                          color: isIncome ? AppTheme.income : AppTheme.expense,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3. 관계별 파이 차트 ──────────────────────────────────────
class _RelationPieChart extends StatefulWidget {
  final List<MapEntry<RelationType, int>> sortedRels;
  const _RelationPieChart({required this.sortedRels});

  @override
  State<_RelationPieChart> createState() => _RelationPieChartState();
}

class _RelationPieChartState extends State<_RelationPieChart> {
  int _touched = -1;

  static const _pieColors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF94A3B8),
  ];

  static const _relationEmojis = ['👨‍👩‍👧', '👥', '🤝', '💼', '🏘️', '📌'];

  @override
  Widget build(BuildContext context) {
    final total =
        widget.sortedRels.fold(0, (s, e) => s + e.value);
    final fmt = NumberFormat('#,###');

    final sections = widget.sortedRels.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final ratio = total == 0 ? 0.0 : e.value / total;
      final isTouched = i == _touched;
      final color = _pieColors[e.key.index % _pieColors.length];

      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: isTouched ? 76 : 62,
        title: ratio < 0.05
            ? ''
            : '${(ratio * 100).toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 44,
              sectionsSpace: 3,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),

        // 터치된 항목 상세 표시
        if (_touched >= 0 && _touched < widget.sortedRels.length) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _pieColors[widget.sortedRels[_touched].key.index %
                      _pieColors.length]
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _relationEmojis[widget.sortedRels[_touched].key.index
                      .clamp(0, _relationEmojis.length - 1)],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.sortedRels[_touched].key.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _pieColors[widget.sortedRels[_touched].key
                              .index %
                          _pieColors.length]),
                ),
                const SizedBox(width: 8),
                Text(
                  '${fmt.format(widget.sortedRels[_touched].value)}원',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${(widget.sortedRels[_touched].value / (total == 0 ? 1 : total) * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        // 범례
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: widget.sortedRels.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final color = _pieColors[e.key.index % _pieColors.length];
            final emoji = _relationEmojis[
                e.key.index.clamp(0, _relationEmojis.length - 1)];
            final isTouched = i == _touched;
            return GestureDetector(
              onTap: () =>
                  setState(() => _touched = _touched == i ? -1 : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTouched
                        ? color.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('$emoji ${e.key.label}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 4),
                  Text('${fmt.format(e.value)}원',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 공통 위젯들 ───────────────────────────────────────────────
class _YearBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _YearBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary
                .withValues(alpha: onTap != null ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: AppTheme.primary
                  .withValues(alpha: onTap != null ? 1 : 0.3),
              size: 20),
        ),
      );
}

class _YearSummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _YearSummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ));
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ]);
}

class _CategoryBar extends StatelessWidget {
  final String emoji, label;
  final int amount, total;
  final Color color;
  const _CategoryBar(
      {required this.emoji,
      required this.label,
      required this.amount,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = amount / total;
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text('${fmt.format(amount)}원',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ]),
            const SizedBox(height: 6),
            Stack(children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(3))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                height: 6,
                width: (MediaQuery.sizeOf(context).width - 100) * ratio,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ]),
          ],
        )),
        const SizedBox(width: 8),
        Text('${(ratio * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MonthData {
  final int month, income, expense;
  const _MonthData(
      {required this.month, required this.income, required this.expense});
}

// ── 장부 탭 아이템 ─────────────────────────────────────────────
class _StatsLedgerItem extends StatelessWidget {
  final EventModel event;
  const _StatsLedgerItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final inc = event.isIncome;
    final isScheduled = event.amount == 0;
    final dateFmt = DateFormat('M월 d일 (E)', 'ko_KR');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PersonHistoryScreen(personName: event.personName),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isScheduled
                  ? const Color(0xFFF5F3FF)
                  : inc
                      ? AppTheme.income.withValues(alpha: 0.1)
                      : AppTheme.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
                child: Text(event.displayEmoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.personName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                    if (isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('예정',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C3AED))),
                      )
                    else
                      Text(event.formattedAmount,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: inc
                                  ? AppTheme.income
                                  : AppTheme.expense)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${event.displayLabel} · ${event.relation.label}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                    Text(dateFmt.format(event.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => EventBottomSheet(
                  initialDate: event.date, eventToEdit: event),
            ),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 15, color: AppTheme.primary),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── 공유 다이얼로그 ────────────────────────────────────────────
class _ShareDialog extends StatefulWidget {
  final List<EventModel> events;
  final int selectedYear;
  const _ShareDialog({required this.events, required this.selectedYear});

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _cardKey = GlobalKey();
  bool _capturing = false;

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/ogogo_${widget.selectedYear}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) Navigator.pop(context);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '오고가고 ${widget.selectedYear}년 경조사 연간 결산 📊',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final year = widget.selectedYear;
    final fmt = NumberFormat('#,###');

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final balance = totalIncome - totalExpense;

    // 경조사별 건수
    final Map<String, int> byCeremony = {};
    for (final e in events) {
      final label = e.displayLabel;
      byCeremony[label] = (byCeremony[label] ?? 0) + 1;
    }
    final topCeremonies = byCeremony.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 캡처 대상 카드
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(children: [
                    Text('오고가고',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    const Spacer(),
                    Text('$year년 결산',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  Container(height: 1.5, color: AppTheme.primary.withValues(alpha: 0.12)),
                  const SizedBox(height: 18),
                  Text('총 ${events.length}건의 경조사',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  // 수입/지출
                  Row(children: [
                    _ShareStatItem(
                        label: '수입',
                        value: '${fmt.format(totalIncome)}원',
                        color: AppTheme.income),
                    const SizedBox(width: 12),
                    _ShareStatItem(
                        label: '지출',
                        value: '${fmt.format(totalExpense)}원',
                        color: AppTheme.expense),
                  ]),
                  const SizedBox(height: 10),
                  // 순 잔액
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.12)),
                    ),
                    child: Row(children: [
                      const Text('순 잔액',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const Spacer(),
                      Text(
                        balance >= 0
                            ? '+${fmt.format(balance)}원'
                            : '-${fmt.format(balance.abs())}원',
                        style: TextStyle(
                            color: balance >= 0
                                ? AppTheme.income
                                : AppTheme.expense,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ]),
                  ),
                  if (topCeremonies.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('많이 참석한 경조사',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: topCeremonies.take(4).map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${e.key} ${e.value}건',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          )).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: Text('오고가고',
                        style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 공유 버튼
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('닫기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _capturing ? null : _capture,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _capturing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(_capturing ? '처리중...' : '이미지로 공유'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ShareStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ShareStatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}
