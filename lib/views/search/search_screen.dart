import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../common/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  _FilterType _filter = _FilterType.all;
  _SortType _sort = _SortType.dateDesc;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allEventsProvider).valueOrNull ?? [];
    final results = _search(all);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(children: [
          // ── 헤더 + 검색바 ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            color: Colors.white,
            child: Column(children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: '이름, 금액, 메모 검색...',
                        hintStyle: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textSecondary, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppTheme.textSecondary, size: 18),
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── 필터 칩 ────────────────────────────────────
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._FilterType.values.map((f) => _FilterChip(
                          label: f.label,
                          isActive: _filter == f,
                          color: f.color,
                          onTap: () => setState(() => _filter = f),
                        )),
                    const SizedBox(width: 8),
                    // 정렬
                    _SortChip(
                      sort: _sort,
                      onChanged: (s) => setState(() => _sort = s),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),

          // ── 결과 카운트 ────────────────────────────────────
          if (_query.isNotEmpty || _filter != _FilterType.all)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppTheme.bgLight,
              child: Text(
                '${results.length}건 검색됨',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),

          // ── 결과 리스트 ────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? _EmptyResult(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: results.length,
                    itemBuilder: (_, i) =>
                        _ResultCard(event: results[i], query: _query),
                  ),
          ),
        ]),
      ),
    );
  }

  List<EventModel> _search(List<EventModel> all) {
    var list = all.where((e) {
      // 필터
      if (_filter == _FilterType.income && !e.isIncome) return false;
      if (_filter == _FilterType.expense && e.isIncome) return false;
      if (_filter == _FilterType.scheduled && !(e.date.isAfter(DateTime.now()))) {
        return false;
      }
      if (_filter != _FilterType.all &&
          _filter != _FilterType.income &&
          _filter != _FilterType.expense &&
          _filter != _FilterType.scheduled) {
        final ceremony = _FilterType.values.indexOf(_filter) - 4;
        if (ceremony >= 0 && e.ceremonyType.index != ceremony) return false;
      }

      // 검색어
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.personName.toLowerCase().contains(q) ||
          e.amount.toString().contains(q) ||
          (e.memo?.toLowerCase().contains(q) ?? false) ||
          e.ceremonyType.label.contains(q) ||
          e.relation.label.contains(q);
    }).toList();

    // 정렬
    switch (_sort) {
      case _SortType.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _SortType.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _SortType.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortType.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
      case _SortType.name:
        list.sort((a, b) => a.personName.compareTo(b.personName));
    }

    return list;
  }
}

// ── 결과 카드 ──────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final EventModel event;
  final String query;
  const _ResultCard({required this.event, required this.query});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final inc = event.isIncome;
    final isScheduled = event.date.isAfter(DateTime.now()) && event.amount == 0;
    final daysLeft = event.date.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            EventBottomSheet(initialDate: event.date, eventToEdit: event),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
        child: Row(children: [
          // 이모지 아이콘
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isScheduled
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: inc
                          ? [const Color(0xFF10B981), const Color(0xFF06B6D4)]
                          : [const Color(0xFFEF4444), const Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(event.ceremonyType.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // 정보
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // 이름 하이라이트
                _HighlightText(
                  text: event.personName,
                  query: query,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(event.ceremonyType.label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                '${event.relation.label} · ${DateFormat('yyyy.MM.dd').format(event.date)}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (event.memo?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                _HighlightText(
                  text: event.memo!,
                  query: query,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                ),
              ],
            ]),
          ),

          // 금액
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isScheduled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'D-$daysLeft',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700),
                ),
              )
            else
              Text(
                '${inc ? '+' : '-'}${fmt.format(event.amount)}원',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: inc ? AppTheme.income : AppTheme.expense,
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ── 하이라이트 텍스트 ──────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text, query;
  final TextStyle style;
  final int? maxLines;
  const _HighlightText(
      {required this.text,
      required this.query,
      required this.style,
      this.maxLines});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: style,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx == -1) {
      return Text(text,
          style: style,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }

    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      text: TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, idx)),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: style.copyWith(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: text.substring(idx + query.length)),
      ]),
    );
  }
}

// ── 빈 결과 ───────────────────────────────────────────────────
class _EmptyResult extends StatelessWidget {
  final String query;
  const _EmptyResult({required this.query});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? '검색어를 입력하세요' : "'$query' 검색 결과가 없어요",
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text('이름, 금액, 메모로 검색해보세요',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ]),
      );
}

// ── 필터 칩 ───────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.isActive,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isActive ? color : Colors.grey[200]!, width: 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textSecondary)),
        ),
      );
}

// ── 정렬 칩 ───────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final _SortType sort;
  final ValueChanged<_SortType> onChanged;
  const _SortChip({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SortSheet(current: sort, onSelected: onChanged),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(children: [
            const Icon(Icons.sort_rounded,
                size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(sort.label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
      );
}

class _SortSheet extends StatelessWidget {
  final _SortType current;
  final ValueChanged<_SortType> onSelected;
  const _SortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('정렬',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ..._SortType.values.map((s) => ListTile(
                leading: Icon(s.icon,
                    color: current == s
                        ? AppTheme.primary
                        : AppTheme.textSecondary),
                title: Text(s.label,
                    style: TextStyle(
                        fontWeight:
                            current == s ? FontWeight.w700 : FontWeight.w400,
                        color: current == s
                            ? AppTheme.primary
                            : AppTheme.textPrimary)),
                trailing: current == s
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  onSelected(s);
                  Navigator.pop(context);
                },
              )),
        ]),
      );
}

// ── 열거형 ────────────────────────────────────────────────────
enum _FilterType {
  all,
  income,
  expense,
  scheduled;

  String get label => switch (this) {
        _FilterType.all => '전체',
        _FilterType.income => '수입',
        _FilterType.expense => '지출',
        _FilterType.scheduled => '예정',
      };

  Color get color => switch (this) {
        _FilterType.all => AppTheme.primary,
        _FilterType.income => AppTheme.income,
        _FilterType.expense => AppTheme.expense,
        _FilterType.scheduled => AppTheme.secondary,
      };
}

enum _SortType {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  name;

  String get label => switch (this) {
        _SortType.dateDesc => '날짜 최신순',
        _SortType.dateAsc => '날짜 오래된순',
        _SortType.amountDesc => '금액 높은순',
        _SortType.amountAsc => '금액 낮은순',
        _SortType.name => '이름순',
      };

  IconData get icon => switch (this) {
        _SortType.dateDesc => Icons.calendar_today_outlined,
        _SortType.dateAsc => Icons.calendar_today_outlined,
        _SortType.amountDesc => Icons.attach_money_rounded,
        _SortType.amountAsc => Icons.attach_money_rounded,
        _SortType.name => Icons.sort_by_alpha_rounded,
      };
}
