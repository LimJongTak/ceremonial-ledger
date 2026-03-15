import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../common/app_theme.dart';

class PersonHistoryScreen extends ConsumerWidget {
  final String personName;
  const PersonHistoryScreen({super.key, required this.personName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEvents = ref.watch(allEventsProvider).valueOrNull ?? [];
    final events = allEvents
        .where((e) => e.personName == personName)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome =
        events.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        events.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final balance = totalIncome - totalExpense;
    final fmt = NumberFormat('#,###');

    // 관계 (가장 최근 이벤트 기준)
    final relation = events.isNotEmpty ? events.first.relation : null;

    // 다음 예정 이벤트
    final now = DateTime.now();
    final nextEvent = events
        .where((e) => e.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = nextEvent.isEmpty ? null : nextEvent.first;

    // 마지막 교류
    final pastEvents = events.where((e) => !e.date.isAfter(now)).toList();
    final lastDate = pastEvents.isEmpty ? null : pastEvents.first.date;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 헤더 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.paddingOf(context).top + 12, 20, 24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기 + 이름 + 건수
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (relation != null || lastDate != null)
                              Row(children: [
                                if (relation != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(relation.label,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary)),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (lastDate != null)
                                  Text(
                                    '마지막 교류 ${DateFormat('yyyy.MM.dd').format(lastDate)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                              ]),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${events.length}건',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 요약 카드
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // 잔액 + 설명
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('총 잔액',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  balance == 0
                                      ? '균형'
                                      : balance > 0
                                          ? '상대가 줄 금액'
                                          : '내가 줄 금액',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              balance == 0
                                  ? '0원'
                                  : '${balance > 0 ? '+' : ''}${fmt.format(balance)}원',
                              style: TextStyle(
                                color: balance >= 0
                                    ? Colors.white
                                    : Colors.red[200],
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryChip(
                                label: '수입',
                                value: '${fmt.format(totalIncome)}원',
                                icon: Icons.arrow_downward_rounded,
                                color: const Color(0xFF6EE7B7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryChip(
                                label: '지출',
                                value: '${fmt.format(totalExpense)}원',
                                icon: Icons.arrow_upward_rounded,
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 다음 예정 이벤트
                  if (upcoming != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20))),
                        builder: (_) => EventBottomSheet(
                            initialDate: upcoming.date,
                            eventToEdit: upcoming),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.secondary.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Text(upcoming.displayEmoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${upcoming.displayLabel} 예정',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.secondary),
                                ),
                                Text(
                                  DateFormat('yyyy년 M월 d일 (E)', 'ko_KR')
                                      .format(upcoming.date),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'D-${upcoming.date.difference(now).inDays}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondary),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 내역 목록 ──────────────────────────────────────────
          if (events.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('내역이 없습니다',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _HistoryItem(event: events[i]),
                  childCount: events.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 요약 칩 ───────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
}

// ── 내역 항목 ──────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final EventModel event;
  const _HistoryItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final inc = event.isIncome;
    final isScheduled = event.amount == 0;
    final fmt = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) =>
            EventBottomSheet(initialDate: event.date, eventToEdit: event),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isScheduled
                  ? const Color(0xFFF5F3FF)
                  : inc
                      ? AppTheme.income.withValues(alpha: 0.1)
                      : AppTheme.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(event.displayEmoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.displayLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                    if (isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.1),
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
                              fontSize: 15,
                              color:
                                  inc ? AppTheme.income : AppTheme.expense)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.relation.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(fmt.format(event.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppTheme.textHint),
        ]),
      ),
    );
  }
}
