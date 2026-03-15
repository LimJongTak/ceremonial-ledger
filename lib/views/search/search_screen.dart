import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // 최근 검색어
  List<String> _recentSearches = [];
  static const _prefKey = 'recent_searches';

  // 고급 필터
  int? _minAmount;
  int? _maxAmount;
  int? _startYear;
  int? _endYear;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      setState(() {
        _recentSearches = List<String>.from(jsonDecode(raw));
      });
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [
      query,
      ..._recentSearches.where((s) => s != query),
    ].take(6).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(updated));
    setState(() => _recentSearches = updated);
  }

  Future<void> _removeRecentSearch(String query) async {
    final updated = _recentSearches.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(updated));
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    setState(() => _recentSearches = []);
  }

  bool get _hasAdvancedFilter =>
      _minAmount != null ||
      _maxAmount != null ||
      _startYear != null ||
      _endYear != null;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allEventsProvider).valueOrNull ?? [];
    final results = _search(all);
    final showRecent =
        _query.isEmpty && _filter == _FilterType.all && !_hasAdvancedFilter;

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
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) _saveRecentSearch(v.trim());
                      },
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
                // 고급 필터 버튼
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _hasAdvancedFilter
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () => _showAdvancedFilter(context, all),
                    ),
                    if (_hasAdvancedFilter)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
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

          // ── 고급 필터 요약 배지 ──────────────────────────
          if (_hasAdvancedFilter)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withValues(alpha: 0.05),
              child: Row(children: [
                const Icon(Icons.filter_alt_rounded,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildFilterSummary(),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _minAmount = null;
                    _maxAmount = null;
                    _startYear = null;
                    _endYear = null;
                  }),
                  child: const Text('초기화',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

          // ── 결과 카운트 ────────────────────────────────────
          if (!showRecent)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppTheme.bgLight,
              child: Text(
                '${results.length}건 검색됨',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),

          // ── 최근 검색어 or 결과 리스트 ──────────────────
          Expanded(
            child: showRecent
                ? _recentSearches.isEmpty
                    ? _EmptyResult(query: _query)
                    : _RecentSearches(
                        searches: _recentSearches,
                        onTap: (s) {
                          _ctrl.text = s;
                          setState(() => _query = s);
                        },
                        onRemove: _removeRecentSearch,
                        onClearAll: _clearRecentSearches,
                      )
                : results.isEmpty
                    ? _EmptyResult(query: _query)
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: results.length,
                        itemBuilder: (_, i) =>
                            _ResultCard(event: results[i], query: _query),
                      ),
          ),
        ]),
      ),
    );
  }

  String _buildFilterSummary() {
    final fmt = NumberFormat('#,###');
    final parts = <String>[];
    if (_minAmount != null && _maxAmount != null) {
      parts.add('${fmt.format(_minAmount!)}~${fmt.format(_maxAmount!)}원');
    } else if (_minAmount != null) {
      parts.add('${fmt.format(_minAmount!)}원 이상');
    } else if (_maxAmount != null) {
      parts.add('${fmt.format(_maxAmount!)}원 이하');
    }
    if (_startYear != null && _endYear != null) {
      parts.add('$_startYear~${_endYear}년');
    } else if (_startYear != null) {
      parts.add('$_startYear년 이후');
    } else if (_endYear != null) {
      parts.add('${_endYear}년 이전');
    }
    return parts.join('  ·  ');
  }

  void _showAdvancedFilter(BuildContext context, List<EventModel> all) {
    final years = all.map((e) => e.date.year).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterSheet(
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        startYear: _startYear,
        endYear: _endYear,
        availableYears: years,
        onApply: (min, max, start, end) => setState(() {
          _minAmount = min;
          _maxAmount = max;
          _startYear = start;
          _endYear = end;
        }),
      ),
    );
  }

  List<EventModel> _search(List<EventModel> all) {
    var list = all.where((e) {
      // 기본 필터
      if (_filter == _FilterType.income && !e.isIncome) return false;
      if (_filter == _FilterType.expense && e.isIncome) return false;
      if (_filter == _FilterType.scheduled &&
          !(e.date.isAfter(DateTime.now()))) return false;
      if (_filter != _FilterType.all &&
          _filter != _FilterType.income &&
          _filter != _FilterType.expense &&
          _filter != _FilterType.scheduled) {
        final ceremony = _FilterType.values.indexOf(_filter) - 4;
        if (ceremony >= 0 && e.ceremonyType.index != ceremony) return false;
      }

      // 금액 범위 필터
      if (_minAmount != null && e.amount < _minAmount!) return false;
      if (_maxAmount != null && e.amount > _maxAmount!) return false;

      // 날짜 범위 필터
      if (_startYear != null && e.date.year < _startYear!) return false;
      if (_endYear != null && e.date.year > _endYear!) return false;

      // 검색어
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.personName.toLowerCase().contains(q) ||
          e.amount.toString().contains(q) ||
          (e.memo?.toLowerCase().contains(q) ?? false) ||
          e.displayLabel.contains(q) ||
          e.relation.label.contains(q);
    }).toList();

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

// ── 최근 검색어 ──────────────────────────────────────────────────
class _RecentSearches extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;
  const _RecentSearches(
      {required this.searches,
      required this.onTap,
      required this.onRemove,
      required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('최근 검색어',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            GestureDetector(
              onTap: onClearAll,
              child: const Text('전체 삭제',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...searches.map((s) => InkWell(
              onTap: () => onTap(s),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(children: [
                  const Icon(Icons.history_rounded,
                      size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(s),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: AppTheme.textHint),
                    ),
                  ),
                ]),
              ),
            )),
      ],
    );
  }
}

// ── 고급 필터 바텀시트 ────────────────────────────────────────────
class _AdvancedFilterSheet extends StatefulWidget {
  final int? minAmount, maxAmount, startYear, endYear;
  final List<int> availableYears;
  final void Function(int? min, int? max, int? startYear, int? endYear)
      onApply;
  const _AdvancedFilterSheet({
    required this.minAmount,
    required this.maxAmount,
    required this.startYear,
    required this.endYear,
    required this.availableYears,
    required this.onApply,
  });

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  int? _startYear;
  int? _endYear;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.minAmount != null
            ? NumberFormat('#,###').format(widget.minAmount)
            : '');
    _maxCtrl = TextEditingController(
        text: widget.maxAmount != null
            ? NumberFormat('#,###').format(widget.maxAmount)
            : '');
    _startYear = widget.startYear;
    _endYear = widget.endYear;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  int? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return cleaned.isEmpty ? null : int.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final allYears = widget.availableYears.isEmpty
        ? [DateTime.now().year]
        : widget.availableYears;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 핸들
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('고급 필터',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 20),

        // 금액 범위
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('금액 범위',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _AmountField(
                controller: _minCtrl, hint: '최소 금액 (원)'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('~',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: _AmountField(
                controller: _maxCtrl, hint: '최대 금액 (원)'),
          ),
        ]),
        const SizedBox(height: 20),

        // 연도 범위
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('연도 범위',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _YearDropdown(
              value: _startYear,
              hint: '시작 연도',
              years: allYears,
              onChanged: (y) => setState(() => _startYear = y),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('~',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: _YearDropdown(
              value: _endYear,
              hint: '종료 연도',
              years: allYears,
              onChanged: (y) => setState(() => _endYear = y),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // 버튼
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _minCtrl.clear();
                _maxCtrl.clear();
                setState(() {
                  _startYear = null;
                  _endYear = null;
                });
                widget.onApply(null, null, null, null);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('초기화'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () {
                widget.onApply(
                  _parseAmount(_minCtrl.text),
                  _parseAmount(_maxCtrl.text),
                  _startYear,
                  _endYear,
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('적용'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _AmountField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style:
            const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontSize: 13, color: AppTheme.textSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: AppTheme.bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

class _YearDropdown extends StatelessWidget {
  final int? value;
  final String hint;
  final List<int> years;
  final ValueChanged<int?> onChanged;
  const _YearDropdown(
      {required this.value,
      required this.hint,
      required this.years,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            hint: Text(hint,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            isExpanded: true,
            style:
                const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            items: [
              const DropdownMenuItem(value: null, child: Text('전체')),
              ...years.map((y) =>
                  DropdownMenuItem(value: y, child: Text('$y년'))),
            ],
            onChanged: onChanged,
          ),
        ),
      );
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
              child: Text(event.displayEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
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
                  child: Text(event.displayLabel,
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
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isScheduled)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
                        fontWeight: current == s
                            ? FontWeight.w700
                            : FontWeight.w400,
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
