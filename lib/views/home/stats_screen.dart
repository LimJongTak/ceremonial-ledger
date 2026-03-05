import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../common/app_theme.dart';

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

class _StatsBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 월별 데이터
    final monthlyData = List.generate(12, (i) {
      final month = i + 1;
      final monthEvents = events.where((e) => e.date.month == month).toList();
      final income =
          monthEvents.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
      final expense =
          monthEvents.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
      return _MonthData(month: month, income: income, expense: expense);
    });

    final maxVal = monthlyData.fold(0, (max, d) {
      final m = d.income > d.expense ? d.income : d.expense;
      return m > max ? m : max;
    });

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);

    // 카테고리별
    final Map<CeremonyType, int> byCategory = {};
    for (final e in events) {
      byCategory[e.ceremonyType] = (byCategory[e.ceremonyType] ?? 0) + e.amount;
    }
    final sortedCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<RelationType, int> byRelation = {};
    for (final e in events) {
      byRelation[e.relation] = (byRelation[e.relation] ?? 0) + e.amount;
    }
    final sortedRels = byRelation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final fmt = NumberFormat('#,###');
    final total = totalIncome + totalExpense;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 헤더
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.paddingOf(context).top + 20, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.gradientPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('통계',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 20),
                // 연도 선택
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _YearBtn(
                      icon: Icons.chevron_left,
                      onTap: () => onYearChanged(selectedYear - 1)),
                  const SizedBox(width: 20),
                  Text('$selectedYear년',
                      style: const TextStyle(
                          color: Colors.white,
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
                // 연간 요약
                Row(children: [
                  Expanded(
                      child: _YearSummaryCard(
                          label: '총 수입',
                          value: '${fmt.format(totalIncome)}원',
                          icon: Icons.arrow_downward_rounded,
                          color: AppTheme.income)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _YearSummaryCard(
                          label: '총 지출',
                          value: '${fmt.format(totalExpense)}원',
                          icon: Icons.arrow_upward_rounded,
                          color: AppTheme.expense)),
                ]),
              ],
            ),
          ),
        ),

        // 월별 바 차트
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ChartTitle(title: '월별 수입/지출'),
                const SizedBox(height: 16),
                // 범례
                Row(children: [
                  _Legend(color: AppTheme.income, label: '수입'),
                  const SizedBox(width: 16),
                  _Legend(color: AppTheme.expense, label: '지출'),
                ]),
                const SizedBox(height: 16),
                // 바 차트
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyData
                        .map((d) => Expanded(
                              child: _BarGroup(
                                  data: d, maxVal: maxVal == 0 ? 1 : maxVal),
                            ))
                        .toList(),
                  ),
                ),
                // 월 라벨
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                      12,
                      (i) => Expanded(
                            child: Text('${i + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary)),
                          )),
                ),
              ],
            ),
          ),
        ),

        // 탭 (경조사별 / 관계별)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 경조사별
                const _ChartTitle(title: '경조사별'),
                const SizedBox(height: 12),
                if (sortedCats.isEmpty)
                  const Center(
                      child: Text('데이터 없음',
                          style: TextStyle(color: AppTheme.textSecondary)))
                else
                  ...sortedCats.map((e) => _CategoryBar(
                        emoji: e.key.emoji,
                        label: e.key.label,
                        amount: e.value,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.primary,
                      )),

                const SizedBox(height: 24),
                // 관계별
                const _ChartTitle(title: '관계별'),
                const SizedBox(height: 12),
                if (sortedRels.isEmpty)
                  const Center(
                      child: Text('데이터 없음',
                          style: TextStyle(color: AppTheme.textSecondary)))
                else
                  ...sortedRels.map((e) => _CategoryBar(
                        emoji: _relationEmoji(e.key),
                        label: e.key.label,
                        amount: e.value,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.secondary,
                      )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _relationEmoji(RelationType r) {
    const emojis = ['👨‍👩‍👧', '👥', '🤝', '💼', '🏘️', '📌'];
    return emojis[r.index.clamp(0, emojis.length - 1)];
  }
}

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
            color: Colors.white.withValues(alpha: onTap != null ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: Colors.white.withValues(alpha: onTap != null ? 1 : 0.3),
              size: 20),
        ),
      );
}

class _YearSummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _YearSummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
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
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      );
}

class _BarGroup extends StatelessWidget {
  final _MonthData data;
  final int maxVal;
  const _BarGroup({required this.data, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    final incRatio = data.income / maxVal;
    final expRatio = data.expense / maxVal;
    const maxH = 140.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 수입 바
          _Bar(height: incRatio * maxH, color: AppTheme.income),
          const SizedBox(width: 1),
          // 지출 바
          _Bar(height: expRatio * maxH, color: AppTheme.expense),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        width: 6,
        height: height < 2 ? 2 : height,
        decoration: BoxDecoration(
          color: height < 2 ? color.withValues(alpha: 0.2) : color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

class _ChartTitle extends StatelessWidget {
  final String title;
  const _ChartTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3));
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
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
