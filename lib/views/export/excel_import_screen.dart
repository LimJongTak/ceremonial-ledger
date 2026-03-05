import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/excel_template_service.dart';

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  bool _isDownloading = false;
  bool _isUploading = false;
  bool _isSaving = false;
  List<ExcelEntry> _entries = [];

  // 양식 다운로드
  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final path = await ExcelTemplateService.instance.downloadTemplate();
      if (path != null) {
        await ExcelTemplateService.instance.openFile(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('양식이 다운로드됐습니다! 내용 작성 후 업로드하세요.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // 파일 업로드 & 파싱
  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
      _entries = [];
    });
    try {
      final entries = await ExcelTemplateService.instance.parseUploadedFile();
      if (mounted) {
        setState(() => _entries = entries);
        if (entries.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인식된 데이터가 없습니다. 양식을 확인해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 읽기 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 선택 항목 저장
  Future<void> _saveSelected() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final selected = _entries.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      for (final entry in selected) {
        await ref.read(eventNotifierProvider.notifier).addEvent(EventModel(
              id: 0,
              date: entry.date,
              personName: entry.name,
              relation: entry.relation,
              ceremonyType: entry.ceremony,
              amount: entry.amount,
              eventType: entry.eventType,
              memo: entry.memo,
              userId: uid,
            ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${selected.length}개 항목이 저장됐습니다!'),
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
    final selectedCount = _entries.where((e) => e.isSelected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('엑셀로 일괄 등록'),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveSelected,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('$selectedCount개 저장',
                      style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
            ),
        ],
      ),
      body: Column(children: [
        // 상단 버튼 영역
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // STEP 1 — 양식 다운로드
            _StepCard(
              step: '1',
              title: '양식 다운로드',
              subtitle: '정해진 엑셀 양식을 다운로드하세요',
              color: const Color(0xFF1A73E8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isDownloading ? null : _downloadTemplate,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_outlined, size: 18),
                  label: Text(_isDownloading ? '다운로드 중...' : '양식 다운로드'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // STEP 2 — 파일 업로드
            _StepCard(
              step: '2',
              title: '파일 업로드',
              subtitle: '작성한 엑셀 파일을 업로드하세요',
              color: const Color(0xFF8B5CF6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isUploading ? null : _uploadFile,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(_isUploading ? '파일 읽는 중...' : 'xlsx 파일 선택'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ]),
        ),

        const Divider(height: 1),

        // 결과 없을 때 안내
        if (_entries.isEmpty && !_isUploading) Expanded(child: _GuideSection()),

        // 결과 목록
        if (_entries.isNotEmpty)
          Expanded(
              child: Column(children: [
            // 전체 선택/해제 바
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('총 ${_entries.length}개 항목 인식됨',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  Row(children: [
                    Text('$selectedCount개 선택',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final all = _entries.every((e) => e.isSelected);
                        setState(() {
                          for (final e in _entries) e.isSelected = !all;
                        });
                      },
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text(
                        _entries.every((e) => e.isSelected) ? '전체 해제' : '전체 선택',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1A73E8)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1),
            // 리스트
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _EntryRow(
                  entry: _entries[i],
                  index: i + 1,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ])),
      ]),
    );
  }
}

// ─── 안내 섹션 ─────────────────────────────────────────────────
class _GuideSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.table_chart_outlined, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text('엑셀 양식 안내',
                  style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ]),
            const SizedBox(height: 16),
            _GuideItem('날짜', 'YYYY-MM-DD 형식 (예: 2024-03-15)'),
            _GuideItem('이름', '2글자 이상 입력'),
            _GuideItem('경조사', '결혼 / 부고 / 돌잔치 / 생일 / 졸업 / 집들이 / 승진 / 기타'),
            _GuideItem('관계', '가족 / 친척 / 친구 / 직장 / 이웃 / 기타'),
            _GuideItem('금액', '숫자만 입력 (예: 50000)'),
            _GuideItem('수입/지출', '"수입" 또는 "지출" 중 하나'),
            _GuideItem('메모', '선택사항'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('예시',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('2024-03-15 | 홍길동 | 결혼 | 친구 | 50000 | 지출 | 결혼 축의금',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  Text('2024-04-01 | 이영희 | 생일 | 가족 | 100000 | 수입 | 생일 용돈',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String label, desc;
  const _GuideItem(this.label, this.desc);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 60,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12))),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
              child: Text(desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
        ]),
      );
}

// ─── 항목 행 ──────────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final ExcelEntry entry;
  final int index;
  final VoidCallback onChanged;
  const _EntryRow(
      {required this.entry, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final inc = entry.eventType == EventType.income;
    final fmt = NumberFormat('#,###');
    final dateStr = DateFormat('yy.MM.dd').format(entry.date);

    return Container(
      decoration: BoxDecoration(
        color: entry.isSelected ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isSelected
              ? (inc ? const Color(0xFF1A73E8) : const Color(0xFFE53935))
                  .withValues(alpha: 0.25)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(children: [
        // 번호 + 체크
        SizedBox(
          width: 50,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$index',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            Checkbox(
              value: entry.isSelected,
              onChanged: (_) {
                entry.isSelected = !entry.isSelected;
                onChanged();
              },
              activeColor: const Color(0xFF1A73E8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
        // 이모지
        Text(entry.ceremony.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        // 내용
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E))),
                  Text(
                    '${inc ? '+' : '-'}${fmt.format(entry.amount)}원',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${entry.ceremony.label} · ${entry.relation.label}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Text(dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
              if (entry.memo != null && entry.memo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('📝 ${entry.memo}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ),
            ]),
          ),
        ),
        const SizedBox(width: 12),
      ]),
    );
  }
}

// ─── Step 카드 ─────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final String step, title, subtitle;
  final Color color;
  final Widget child;
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
                child: Text(step,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 10),
                child,
              ])),
        ]),
      );
}
