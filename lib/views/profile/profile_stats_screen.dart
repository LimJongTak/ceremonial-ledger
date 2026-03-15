import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../common/app_theme.dart';
import '../person/person_history_screen.dart';

enum StatsType { income, expense, all }

class ProfileStatsScreen extends ConsumerWidget {
  final StatsType type;
  const ProfileStatsScreen({super.key, required this.type});

  String get _title => switch (type) {
        StatsType.income => '총 수입',
        StatsType.expense => '총 지출',
        StatsType.all => '전체 내역',
      };

  Color get _color => switch (type) {
        StatsType.income => AppTheme.income,
        StatsType.expense => AppTheme.expense,
        StatsType.all => AppTheme.gold,
      };

  List<EventModel> _filter(List<EventModel> events) => switch (type) {
        StatsType.income => events.where((e) => e.isIncome).toList(),
        StatsType.expense => events.where((e) => !e.isIncome).toList(),
        StatsType.all => events,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEvents = ref.watch(allEventsProvider).valueOrNull ?? [];
    final events = _filter(allEvents)
      ..sort((a, b) => b.date.compareTo(a.date));

    final total = events.fold(0, (s, e) => s + e.amount);
    final fmt = NumberFormat('#,###');

    // 연도별 그룹핑: [년도(int), EventModel, EventModel, ...]
    final List<Object> items = [];
    int? currentYear;
    for (final e in events) {
      if (e.date.year != currentYear) {
        currentYear = e.date.year;
        items.add(currentYear);
      }
      items.add(e);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 헤더
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.paddingOf(context).top + 56, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Container(
                        width: 8,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const SizedBox(width: 18),
                      Text(
                        '${fmt.format(total)}원',
                        style: TextStyle(
                            color: _color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${events.length}건',
                          style: TextStyle(
                              color: _color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // 내역 없을 때
          if (events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('내역이 없습니다',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final item = items[i];
                    if (item is int) {
                      // 연도 헤더
                      final yearEvents = events
                          .where((e) => e.date.year == item)
                          .toList();
                      final yearTotal =
                          yearEvents.fold(0, (s, e) => s + e.amount);
                      return _YearHeader(
                          year: item,
                          total: yearTotal,
                          count: yearEvents.length,
                          color: _color);
                    }
                    return _StatsItem(event: item as EventModel);
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  final int year, total, count;
  final Color color;
  const _YearHeader(
      {required this.year,
      required this.total,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            '$year년',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${fmt.format(total)}원 · ${count}건',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsItem extends ConsumerWidget {
  final EventModel event;
  const _StatsItem({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inc = event.isIncome;
    final dateStr = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(event.date);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonHistoryScreen(personName: event.personName),
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
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: inc
                  ? AppTheme.income.withValues(alpha: 0.1)
                  : AppTheme.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(event.ceremonyType.emoji,
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
                    Text(
                      event.formattedAmount,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: inc ? AppTheme.income : AppTheme.expense),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${event.ceremonyType.label} · ${event.relation.label}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    Text(dateStr,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) =>
                  EventBottomSheet(initialDate: event.date, eventToEdit: event),
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
