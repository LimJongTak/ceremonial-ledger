import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';

// 등록 모드
enum _EntryMode { scheduled, confirmed }

class EventBottomSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final EventModel? eventToEdit;

  const EventBottomSheet({
    super.key,
    required this.initialDate,
    this.eventToEdit,
  });

  @override
  ConsumerState<EventBottomSheet> createState() => _State();
}

class _State extends ConsumerState<EventBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  EventType _type = EventType.expense;
  RelationType _rel = RelationType.friend;
  CeremonyType _cer = CeremonyType.wedding;
  late DateTime _date;
  _EntryMode _mode = _EntryMode.confirmed;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _date = widget.initialDate;

    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _nameCtrl.text = e.personName;
      _amtCtrl.text = e.amount == 0 ? '' : e.amount.toString();
      _memoCtrl.text = e.memo ?? '';
      _type = e.eventType;
      _rel = e.relation;
      _cer = e.ceremonyType;
      _date = e.date;
      // 금액이 0이면 예정 모드로
      _mode = e.amount == 0 ? _EntryMode.scheduled : _EntryMode.confirmed;
    } else {
      // 미래 날짜면 예정 모드 기본값
      if (widget.initialDate.isAfter(DateTime.now())) {
        _mode = _EntryMode.scheduled;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    _memoCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── 날짜 선택 ────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.eventToEdit != null;
    final isScheduled = _mode == _EntryMode.scheduled;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? '내역 수정' : '내역 추가',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(children: [
                        if (isEdit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFEF4444)),
                            onPressed: _delete,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── 모드 선택 (예정 / 확정) ──────────────────
                  if (!isEdit) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        _ModeTab(
                          icon: Icons.event_outlined,
                          label: '예정된 일정',
                          sublabel: '금액 선택사항',
                          isActive: isScheduled,
                          activeColor: const Color(0xFF7C3AED),
                          onTap: () {
                            setState(() => _mode = _EntryMode.scheduled);
                            _animCtrl.reset();
                            _animCtrl.forward();
                          },
                        ),
                        _ModeTab(
                          icon: Icons.receipt_long_outlined,
                          label: '금액 확정',
                          sublabel: '수입 / 지출 기록',
                          isActive: !isScheduled,
                          activeColor: const Color(0xFF2563EB),
                          onTap: () {
                            setState(() => _mode = _EntryMode.confirmed);
                            _animCtrl.reset();
                            _animCtrl.forward();
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── 확정 모드: 수입/지출 선택 ────────────────
                  if (!isScheduled) ...[
                    Row(
                      children: EventType.values.map((t) {
                        final sel = _type == t;
                        final color = t == EventType.income
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    sel ? color : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                Icon(
                                  t == EventType.income
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: sel ? Colors.white : color,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: sel ? Colors.white : color,
                                  ),
                                ),
                                Text(
                                  t.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: sel
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : color.withValues(alpha: 0.7),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── 예정 모드: 안내 배너 ─────────────────────
                  if (isScheduled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '예정된 일정은 금액 없이 등록할 수 있습니다.\n나중에 수정하여 금액을 추가하세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── 이름 ────────────────────────────────────
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _deco('이름 *', Icons.person_outline_rounded),
                    validator: (v) => v?.isEmpty == true ? '이름을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── 날짜 선택 버튼 ───────────────────────────
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 20, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_date.year}년 ${_date.month}월 ${_date.day}일',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ),
                        _date.isAfter(DateTime.now())
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'D-${_date.difference(DateTime.now()).inDays}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8), size: 20),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 금액 (확정은 필수, 예정은 선택) ──────────
                  TextFormField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _deco(
                      isScheduled ? '금액 (선택사항)' : '금액 (원) *',
                      Icons.attach_money_rounded,
                    ),
                    validator: (v) {
                      if (!isScheduled) {
                        if (v?.isEmpty == true) return '금액을 입력해주세요';
                        if (int.tryParse(v!) == null) return '숫자로 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── 관계 + 경조사 ────────────────────────────
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<RelationType>(
                        value: _rel,
                        decoration: _deco('관계', Icons.people_outline_rounded),
                        isExpanded: true,
                        items: RelationType.values
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _rel = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<CeremonyType>(
                        value: _cer,
                        decoration: _deco('경조사', Icons.celebration_outlined),
                        isExpanded: true,
                        items: CeremonyType.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('${c.emoji} ${c.label}',
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _cer = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ── 메모 ────────────────────────────────────
                  TextFormField(
                    controller: _memoCtrl,
                    decoration: _deco('메모 (선택사항)', Icons.note_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // ── 저장 버튼 ────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: isScheduled
                          ? const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : LinearGradient(
                              colors: _type == EventType.income
                                  ? [
                                      const Color(0xFF10B981),
                                      const Color(0xFF06B6D4)
                                    ]
                                  : [
                                      const Color(0xFFEF4444),
                                      const Color(0xFFF59E0B)
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isScheduled
                                  ? const Color(0xFF7C3AED)
                                  : _type == EventType.income
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.check_rounded
                                    : isScheduled
                                        ? Icons.event_available_outlined
                                        : Icons.save_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit
                                    ? '수정 완료'
                                    : isScheduled
                                        ? '일정 등록'
                                        : '내역 저장',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final isScheduled = _mode == _EntryMode.scheduled;
    final amtStr = _amtCtrl.text.trim();
    final amount = amtStr.isEmpty ? 0 : int.parse(amtStr);

    final e = EventModel(
      id: widget.eventToEdit?.id ?? 0,
      date: _date,
      personName: _nameCtrl.text.trim(),
      relation: _rel,
      ceremonyType: _cer,
      amount: amount,
      eventType: isScheduled && amount == 0 ? EventType.expense : _type,
      memo: _memoCtrl.text.isEmpty ? null : _memoCtrl.text.trim(),
      userId: uid,
      firestoreId: widget.eventToEdit?.firestoreId,
    );

    await ref.read(eventNotifierProvider.notifier).addEvent(e);
    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('삭제 확인', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('${widget.eventToEdit?.personName ?? ''} 내역을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true && widget.eventToEdit != null) {
      await ref.read(eventNotifierProvider.notifier).deleteEvent(
            widget.eventToEdit!.id,
            firestoreId: widget.eventToEdit!.firestoreId,
          );
      if (mounted) Navigator.pop(context);
    }
  }
}

// ── 모드 탭 위젯 ──────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Column(children: [
              Icon(icon,
                  size: 20,
                  color: isActive ? activeColor : const Color(0xFF94A3B8)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? activeColor : const Color(0xFF94A3B8))),
              Text(sublabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? activeColor.withValues(alpha: 0.7)
                          : const Color(0xFFCBD5E1))),
            ]),
          ),
        ),
      );
}
