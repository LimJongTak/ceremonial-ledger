import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ledgerSummaryProvider);
    final year = ref.watch(filterYearProvider);
    final month = ref.watch(filterMonthProvider);

    return Scaffold(
      body: CustomScrollView(slivers: [
        // 상단 헤더
        SliverAppBar(
          pinned: true,
          expandedHeight: 195,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    _FilterChip(
                      label: '$year년',
                      onTap: () => _showYearPicker(context, ref, year),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: month != null ? '$month월' : '전체',
                      onTap: () => _showMonthPicker(context, ref, month),
                    ),
                    const Spacer(),
                    Text('${summary.events.length}건',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _SummaryCard(
                            label: '총 수입',
                            amount: summary.totalIncome,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _SummaryCard(
                            label: '총 지출',
                            amount: summary.totalExpense,
                            color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _SummaryCard(
                            label: '잔액',
                            amount: summary.balance,
                            color: summary.balance >= 0
                                ? Colors.white
                                : Colors.red[200]!)),
                  ]),
                ],
              ),
            ),
          ),
        ),

        if (summary.events.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('해당 기간의 내역이 없습니다',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ],
              ),
            ),
          )
        else ...[
          // 카테고리별 통계
          SliverToBoxAdapter(
            child: _CategoryStats(events: summary.events),
          ),
          // 내역 목록
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _LedgerItem(event: summary.events[i]),
                childCount: summary.events.length,
              ),
            ),
          ),
        ],
      ]),
    );
  }

  void _showYearPicker(BuildContext ctx, WidgetRef ref, int cur) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('완료'), onPressed: () => Navigator.pop(ctx)),
          ]),
          Expanded(
              child: CupertinoPicker(
            itemExtent: 36,
            scrollController:
                FixedExtentScrollController(initialItem: cur - 2020),
            onSelectedItemChanged: (i) =>
                ref.read(filterYearProvider.notifier).state = 2020 + i,
            children:
                List.generate(11, (i) => Center(child: Text('${2020 + i}년'))),
          )),
        ]),
      ),
    );
  }

  void _showMonthPicker(BuildContext ctx, WidgetRef ref, int? cur) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('완료'), onPressed: () => Navigator.pop(ctx)),
          ]),
          Expanded(
              child: CupertinoPicker(
            itemExtent: 36,
            scrollController:
                FixedExtentScrollController(initialItem: cur ?? 0),
            onSelectedItemChanged: (i) => ref
                .read(filterMonthProvider.notifier)
                .state = i == 0 ? null : i,
            children: [
              const Center(child: Text('전체')),
              ...List.generate(12, (i) => Center(child: Text('${i + 1}월'))),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─── 카테고리별 통계 ───────────────────────────────────────────
class _CategoryStats extends StatefulWidget {
  final List<EventModel> events;
  const _CategoryStats({required this.events});

  @override
  State<_CategoryStats> createState() => _CategoryStatsState();
}

class _CategoryStatsState extends State<_CategoryStats> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 경조사 종류별 합계
    final Map<CeremonyType, int> incomeByCategory = {};
    final Map<CeremonyType, int> expenseByCategory = {};

    for (final e in widget.events) {
      if (e.isIncome) {
        incomeByCategory[e.ceremonyType] =
            (incomeByCategory[e.ceremonyType] ?? 0) + e.amount;
      } else {
        expenseByCategory[e.ceremonyType] =
            (expenseByCategory[e.ceremonyType] ?? 0) + e.amount;
      }
    }

    // 관계별 합계
    final Map<RelationType, int> byRelation = {};
    for (final e in widget.events) {
      byRelation[e.relation] = (byRelation[e.relation] ?? 0) + e.amount;
    }

    final sortedCeremony = CeremonyType.values
        .where(
            (c) => (incomeByCategory[c] ?? 0) + (expenseByCategory[c] ?? 0) > 0)
        .toList()
      ..sort((a, b) => ((incomeByCategory[b] ?? 0) +
              (expenseByCategory[b] ?? 0))
          .compareTo((incomeByCategory[a] ?? 0) + (expenseByCategory[a] ?? 0)));

    final sortedRelation = RelationType.values
        .where((r) => (byRelation[r] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (byRelation[b] ?? 0).compareTo(byRelation[a] ?? 0));

    final totalAmount = widget.events.fold(0, (s, e) => s + e.amount);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart_outline,
                        color: Color(0xFF1A73E8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('카테고리별 통계',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 경조사 종류별 (항상 표시)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('경조사별',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500])),
                const SizedBox(height: 8),
                ...sortedCeremony
                    .take(_expanded ? sortedCeremony.length : 3)
                    .map((c) {
                  final income = incomeByCategory[c] ?? 0;
                  final expense = expenseByCategory[c] ?? 0;
                  final total = income + expense;
                  final ratio = totalAmount > 0 ? total / totalAmount : 0.0;
                  return _CategoryRow(
                    emoji: c.emoji,
                    label: c.label,
                    income: income,
                    expense: expense,
                    ratio: ratio,
                  );
                }),
                if (!_expanded && sortedCeremony.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _expanded = true),
                      child: Text('+ ${sortedCeremony.length - 3}개 더보기',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1A73E8))),
                    ),
                  ),
              ],
            ),
          ),

          // 관계별 (펼쳤을 때만)
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('관계별',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  ...sortedRelation.map((r) {
                    final amount = byRelation[r] ?? 0;
                    final ratio = totalAmount > 0 ? amount / totalAmount : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              [
                                '👨‍👩‍👧',
                                '👥',
                                '🤝',
                                '💼',
                                '🏘️',
                                '📌'
                              ][r.index],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.label,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A2E))),
                                  Text(
                                    '${NumberFormat('#,###').format(amount)}원',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF8B5CF6)),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String emoji, label;
  final int income, expense;
  final double ratio;
  const _CategoryRow({
    required this.emoji,
    required this.label,
    required this.income,
    required this.expense,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E))),
                  Row(children: [
                    if (income > 0)
                      Text('+${fmt.format(income)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.w600)),
                    if (income > 0 && expense > 0)
                      const Text(
                        '  ',
                      ),
                    if (expense > 0)
                      Text('-${fmt.format(expense)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey[100],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1A73E8)),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(ratio * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ─── 기존 위젯들 ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const Icon(Icons.expand_more, color: Colors.white, size: 16),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        Text('${NumberFormat('#,###').format(amount)}원',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _LedgerItem extends ConsumerWidget {
  final EventModel event;
  const _LedgerItem({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inc = event.isIncome;
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(event.date);

    return Dismissible(
      key: Key(event.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.red[400], borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('삭제'),
          content: Text('${event.personName} 내역을 삭제할까요?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소')),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제')),
          ],
        ),
      ),
      onDismissed: (_) => ref
          .read(eventNotifierProvider.notifier)
          .deleteEvent(event.id, firestoreId: event.firestoreId),
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) =>
              EventBottomSheet(initialDate: event.date, eventToEdit: event),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: inc ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
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
                            color: Color(0xFF1A1A2E))),
                    Text(event.formattedAmount,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: inc
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFFE53935))),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${event.ceremonyType.label} · ${event.relation.label}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                    Text(dateStr,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}
