import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';

class OcrRegisterScreen extends ConsumerStatefulWidget {
  const OcrRegisterScreen({super.key});

  @override
  ConsumerState<OcrRegisterScreen> createState() => _OcrRegisterScreenState();
}

class _OcrRegisterScreenState extends ConsumerState<OcrRegisterScreen> {
  File? _image;
  bool _isProcessing = false;
  bool _isSaving = false;
  List<_ParsedEntry> _entries = [];
  String _rawText = '';

  // OCR 실행
  Future<void> _pickAndRecognize(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _isProcessing = true;
      _entries = [];
      _rawText = '';
    });

    try {
      final inputImage = InputImage.fromFile(_image!);
      final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      setState(() {
        _rawText = recognized.text;
        _entries = _parseText(recognized.text);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 텍스트 파싱 → 항목 리스트
  List<_ParsedEntry> _parseText(String text) {
    final entries = <_ParsedEntry>[];
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    for (final line in lines) {
      final entry = _parseLine(line.trim());
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  // 한 줄 파싱: "홍길동 결혼 50000" 또는 "김철수 50,000 친구" 형식
  _ParsedEntry? _parseLine(String line) {
    // 금액 추출 (숫자 + 콤마 패턴)
    final amountRegex = RegExp(r'(\d{1,3}(?:,\d{3})*|\d+)(?:원)?');
    final amountMatch = amountRegex.firstMatch(line);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = int.tryParse(amountStr);
    if (amount == null || amount < 1000) return null;

    // 금액 제거 후 나머지 텍스트
    final rest = line.replaceAll(amountRegex, '').trim();
    if (rest.isEmpty) return null;

    // 이름 추출 (첫 번째 2-4글자 한글)
    final nameRegex = RegExp(r'([가-힣]{2,4})');
    final nameMatch = nameRegex.firstMatch(rest);
    final name = nameMatch?.group(1) ?? rest.split(' ').first;

    // 경조사 타입 추출
    CeremonyType ceremony = CeremonyType.other;
    if (line.contains('결혼') || line.contains('웨딩')) {
      ceremony = CeremonyType.wedding;
    } else if (line.contains('부고') || line.contains('장례') || line.contains('조의')) {
      ceremony = CeremonyType.funeral;
    } else if (line.contains('돌') || line.contains('백일')) {
      ceremony = CeremonyType.babyShower;
    } else if (line.contains('생일')) {
      ceremony = CeremonyType.birthday;
    } else if (line.contains('졸업')) {
      ceremony = CeremonyType.graduation;
    } else if (line.contains('집들이')) {
      ceremony = CeremonyType.houseWarming;
    } else if (line.contains('승진')) {
      ceremony = CeremonyType.promotion;
    }

    // 관계 추출
    RelationType relation = RelationType.other;
    if (line.contains('가족') || line.contains('부모') || line.contains('형제')) {
      relation = RelationType.family;
    } else if (line.contains('친척') || line.contains('친인척')) {
      relation = RelationType.relative;
    } else if (line.contains('친구') || line.contains('동창') || line.contains('동기')) {
      relation = RelationType.friend;
    } else if (line.contains('직장') || line.contains('회사') || line.contains('동료')) {
      relation = RelationType.colleague;
    } else if (line.contains('이웃')) {
      relation = RelationType.neighbor;
    }

    // 수입/지출 추출
    EventType eventType = EventType.expense; // 기본값: 지출
    if (line.contains('받') || line.contains('수입') || line.contains('+')) {
      eventType = EventType.income;
    }

    return _ParsedEntry(
      name: name,
      amount: amount,
      ceremony: ceremony,
      relation: relation,
      eventType: eventType,
      date: DateTime.now(),
      isSelected: true,
    );
  }

  // 전체 저장
  Future<void> _saveAll() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final selected = _entries.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      for (final entry in selected) {
        final model = EventModel(
          id: 0,
          date: entry.date,
          personName: entry.name,
          relation: entry.relation,
          ceremonyType: entry.ceremony,
          amount: entry.amount,
          eventType: entry.eventType,
          memo: null,
          userId: uid,
        );
        await ref.read(eventNotifierProvider.notifier).addEvent(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected.length}개 항목이 저장됐습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('카메라로 일괄 등록'),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveAll,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      '${_entries.where((e) => e.isSelected).length}개 저장',
                      style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 촬영/선택 버튼
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.camera_alt,
                  label: '카메라 촬영',
                  color: const Color(0xFF1A73E8),
                  onTap: () => _pickAndRecognize(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.photo_library,
                  label: '갤러리 선택',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _pickAndRecognize(ImageSource.gallery),
                ),
              ),
            ]),
          ),

          // 안내 문구
          if (_entries.isEmpty && !_isProcessing)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  // 이미지 미리보기
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!,
                          height: 200,
                          fit: BoxFit.cover,
                          width: double.infinity),
                    ),
                  const SizedBox(height: 20),
                  // 인식 형식 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 18),
                          const SizedBox(width: 8),
                          Text('인식 가능한 형식',
                              style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 12),
                        const _GuideRow('홍길동 결혼 50,000'),
                        const _GuideRow('김철수 친구 장례 30000원'),
                        const _GuideRow('이영희 직장 집들이 100,000 받음'),
                        const _GuideRow('박민준 50000 졸업'),
                        const SizedBox(height: 8),
                        Text('• 이름, 금액은 필수\n• 경조사/관계/수입지출 키워드 포함시 자동 분류',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[600])),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

          // 로딩
          if (_isProcessing)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('텍스트 인식 중...'),
                  ],
                ),
              ),
            ),

          // 결과 목록
          if (_entries.isNotEmpty)
            Expanded(
              child: Column(children: [
                // 이미지 + 원본 텍스트
                if (_image != null)
                  GestureDetector(
                    onTap: () => _showRawText(context),
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: const Center(
                          child: Text('원본 텍스트 보기',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),

                // 전체 선택/해제
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('인식된 항목 ${_entries.length}개',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      TextButton(
                        onPressed: () {
                          final allSelected =
                              _entries.every((e) => e.isSelected);
                          setState(() {
                            for (final e in _entries) {
                              e.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          _entries.every((e) => e.isSelected)
                              ? '전체 해제'
                              : '전체 선택',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // 항목 리스트
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) => _EntryCard(
                      entry: _entries[i],
                      onChanged: () => setState(() {}),
                      onEdit: () => _editEntry(context, i),
                    ),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _showRawText(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('인식된 원본 텍스트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
                child: SingleChildScrollView(
              child: Text(_rawText, style: const TextStyle(fontSize: 13)),
            )),
          ],
        ),
      ),
    );
  }

  void _editEntry(BuildContext context, int index) {
    final entry = _entries[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditEntrySheet(
        entry: entry,
        onSave: (updated) {
          setState(() => _entries[index] = updated);
        },
      ),
    );
  }
}

// ─── 파싱된 항목 모델 ──────────────────────────────────────────
class _ParsedEntry {
  String name;
  int amount;
  CeremonyType ceremony;
  RelationType relation;
  EventType eventType;
  DateTime date;
  bool isSelected;

  _ParsedEntry({
    required this.name,
    required this.amount,
    required this.ceremony,
    required this.relation,
    required this.eventType,
    required this.date,
    required this.isSelected,
  });

  _ParsedEntry copyWith({
    String? name,
    int? amount,
    CeremonyType? ceremony,
    RelationType? relation,
    EventType? eventType,
    DateTime? date,
  }) =>
      _ParsedEntry(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        ceremony: ceremony ?? this.ceremony,
        relation: relation ?? this.relation,
        eventType: eventType ?? this.eventType,
        date: date ?? this.date,
        isSelected: isSelected,
      );
}

// ─── 항목 카드 ─────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final _ParsedEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onEdit;
  const _EntryCard(
      {required this.entry, required this.onChanged, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final inc = entry.eventType == EventType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: entry.isSelected ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isSelected
              ? (inc ? const Color(0xFF1A73E8) : const Color(0xFFE53935))
                  .withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(children: [
        // 체크박스
        Checkbox(
          value: entry.isSelected,
          onChanged: (_) {
            entry.isSelected = !entry.isSelected;
            onChanged();
          },
          activeColor: const Color(0xFF1A73E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        // 이모지
        Text(entry.ceremony.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        // 내용
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E))),
                    Text(
                      '${inc ? '+' : '-'}${NumberFormat('#,###').format(entry.amount)}원',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: inc
                              ? const Color(0xFF1A73E8)
                              : const Color(0xFFE53935)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.ceremony.label} · ${entry.relation.label} · ${DateFormat('M/d').format(entry.date)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
        // 수정 버튼
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[400]),
          onPressed: onEdit,
        ),
      ]),
    );
  }
}

// ─── 항목 수정 시트 ────────────────────────────────────────────
class _EditEntrySheet extends StatefulWidget {
  final _ParsedEntry entry;
  final Function(_ParsedEntry) onSave;
  const _EditEntrySheet({required this.entry, required this.onSave});

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amtCtrl;
  late CeremonyType _ceremony;
  late RelationType _relation;
  late EventType _eventType;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.entry.name);
    _amtCtrl = TextEditingController(text: widget.entry.amount.toString());
    _ceremony = widget.entry.ceremony;
    _relation = widget.entry.relation;
    _eventType = widget.entry.eventType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String l, IconData i) => InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('항목 수정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // 수입/지출
          Row(
              children: EventType.values.map((t) {
            final sel = _eventType == t;
            final c = t == EventType.income
                ? const Color(0xFF1A73E8)
                : const Color(0xFFE53935);
            return Expanded(
                child: GestureDetector(
              onTap: () => setState(() => _eventType = t),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? c : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _nameCtrl,
                    decoration: _deco('이름', Icons.person_outline))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _deco('금액', Icons.attach_money))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<RelationType>(
              initialValue: _relation,
              decoration: _deco('관계', Icons.people_outline),
              isExpanded: true,
              items: RelationType.values
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child:
                          Text(r.label, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _relation = v!),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<CeremonyType>(
              initialValue: _ceremony,
              decoration: _deco('경조사', Icons.event),
              isExpanded: true,
              items: CeremonyType.values
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}',
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _ceremony = v!),
            )),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final updated = widget.entry.copyWith(
                name: _nameCtrl.text.trim(),
                amount: int.tryParse(_amtCtrl.text) ?? widget.entry.amount,
                ceremony: _ceremony,
                relation: _relation,
                eventType: _eventType,
              );
              widget.onSave(updated);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('수정 완료',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ─── 유틸 위젯 ─────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
}

class _GuideRow extends StatelessWidget {
  final String text;
  const _GuideRow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
        ]),
      );
}
