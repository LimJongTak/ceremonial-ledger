import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../person/person_history_screen.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  bool _selectMode = false;
  final Set<int> _selectedIds = {};

  void _enterSelectMode() => setState(() {
        _selectMode = true;
        _selectedIds.clear();
      });

  void _exitSelectMode() => setState(() {
        _selectMode = false;
        _selectedIds.clear();
      });

  void _toggleSelect(int id) => setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      });

  void _selectAll(List<EventModel> events) => setState(() {
        _selectedIds.addAll(events.map((e) => e.id));
      });

  void _deselectAll() => setState(() => _selectedIds.clear());

  Future<void> _deleteSelected(List<EventModel> events) async {
    final toDelete = events.where((e) => _selectedIds.contains(e.id)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일괄 삭제'),
        content: Text('선택한 ${toDelete.length}건의 내역을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(eventNotifierProvider.notifier)
          .deleteMultipleEvents(toDelete);
      _exitSelectMode();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => _showYearPicker(context, year),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: month != null ? '$month월' : '전체',
                      onTap: () => _showMonthPicker(context, month),
                    ),
                    const Spacer(),
                    if (_selectMode) ...[
                      GestureDetector(
                        onTap: () {
                          final all = _selectedIds.length == summary.events.length;
                          all ? _deselectAll() : _selectAll(summary.events);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedIds.length == summary.events.length
                                ? '전체 해제'
                                : '전체 선택',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _exitSelectMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('취소',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else ...[
                      Text('${summary.events.length}건',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _enterSelectMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('선택',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
          // 카테고리별 통계 (선택 모드에서는 숨김)
          if (!_selectMode)
            SliverToBoxAdapter(
              child: _CategoryStats(events: summary.events),
            ),
          // 내역 목록
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                16, _selectMode ? 12 : 0, 16, _selectMode ? 100 : 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _LedgerItem(
                  event: summary.events[i],
                  selectMode: _selectMode,
                  isSelected: _selectedIds.contains(summary.events[i].id),
                  onToggle: () => _toggleSelect(summary.events[i].id),
                  onLongPress: _selectMode
                      ? null
                      : () {
                          _enterSelectMode();
                          _toggleSelect(summary.events[i].id);
                        },
                ),
                childCount: summary.events.length,
              ),
            ),
          ),
        ],
      ]),

      // 선택 모드 하단 액션바
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedIds.isEmpty
                            ? '항목을 선택하세요'
                            : '${_selectedIds.length}건 선택됨',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedIds.isEmpty
                                ? Colors.grey[400]
                                : const Color(0xFF1A1A2E)),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () => _deleteSelected(summary.events),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        disabledBackgroundColor:
                            Colors.grey[200],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('삭제',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _showYearPicker(BuildContext ctx, int cur) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('완료'),
                onPressed: () => Navigator.pop(ctx)),
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

  void _showMonthPicker(BuildContext ctx, int? cur) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            CupertinoButton(
                child: const Text('완료'),
                onPressed: () => Navigator.pop(ctx)),
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
    final Map<String, int> incomeByCategory = {};
    final Map<String, int> expenseByCategory = {};

    for (final e in widget.events) {
      final key = e.displayLabel;
      if (e.isIncome) {
        incomeByCategory[key] = (incomeByCategory[key] ?? 0) + e.amount;
      } else {
        expenseByCategory[key] = (expenseByCategory[key] ?? 0) + e.amount;
      }
    }

    final Map<RelationType, int> byRelation = {};
    for (final e in widget.events) {
      byRelation[e.relation] = (byRelation[e.relation] ?? 0) + e.amount;
    }

    // 경조사별 (displayLabel 기준)
    final Map<String, String> labelToEmoji = {};
    for (final e in widget.events) {
      labelToEmoji.putIfAbsent(e.displayLabel, () => e.displayEmoji);
    }

    final sortedCeremony = labelToEmoji.keys.toList()
      ..sort((a, b) => ((incomeByCategory[b] ?? 0) + (expenseByCategory[b] ?? 0))
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
                    .map((label) {
                  final income = incomeByCategory[label] ?? 0;
                  final expense = expenseByCategory[label] ?? 0;
                  final total = income + expense;
                  final ratio = totalAmount > 0 ? total / totalAmount : 0.0;
                  return _CategoryRow(
                    emoji: labelToEmoji[label] ?? '📝',
                    label: label,
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
                              ['👨‍👩‍👧', '👥', '🤝', '💼', '🏘️', '📌'][r.index],
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
                    if (income > 0 && expense > 0) const Text('  '),
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
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF1A73E8)),
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
  final bool selectMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const _LedgerItem({
    required this.event,
    required this.selectMode,
    required this.isSelected,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inc = event.isIncome;
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(event.date);

    final card = GestureDetector(
      onLongPress: onLongPress,
      onTap: selectMode
          ? onToggle
          : () => Navigator.push(
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
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(children: [
          // 체크박스 (선택 모드)
          if (selectMode) ...[
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.grey[300]!,
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: inc ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
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
                      '${event.displayLabel} · ${event.relation.label}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(dateStr,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          )),
          if (!selectMode) ...[
            const SizedBox(width: 8),
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 15, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ]),
      ),
    );

    // 선택 모드에서는 Dismissible 비활성화
    if (selectMode) return card;

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
      child: card,
    );
  }
}
