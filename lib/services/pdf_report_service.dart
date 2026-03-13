import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/event_model.dart';

class PdfReportService {
  PdfReportService._();
  static final instance = PdfReportService._();

  final _fmt = NumberFormat('#,###');

  // ── PDF 생성 및 공유 ─────────────────────────────────────────
  Future<void> generateAndShare({
    required List<EventModel> events,
    required DateTime startDate,
    required DateTime endDate,
    List<CeremonyType>? categories,
    required String userName,
  }) async {
    final pdf = await _buildPdf(
      events: events,
      startDate: startDate,
      endDate: endDate,
      categories: categories,
      userName: userName,
    );

    final filenameFmt = DateFormat('yyyyMMdd');
    final filename =
        '경조사결산_${filenameFmt.format(startDate)}_${filenameFmt.format(endDate)}.pdf';

    await Printing.sharePdf(bytes: pdf, filename: filename);
  }

  // ── PDF 미리보기 화면 열기 ────────────────────────────────────
  Future<void> previewPdf({
    required BuildContext context,
    required List<EventModel> events,
    required DateTime startDate,
    required DateTime endDate,
    List<CeremonyType>? categories,
    required String userName,
  }) async {
    final titleFmt = DateFormat('yyyy.MM.dd');
    final title =
        '${titleFmt.format(startDate)} ~ ${titleFmt.format(endDate)} 결산';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  final pdf = await _buildPdf(
                    events: events,
                    startDate: startDate,
                    endDate: endDate,
                    categories: categories,
                    userName: userName,
                  );
                  final filenameFmt = DateFormat('yyyyMMdd');
                  final filename =
                      '경조사결산_${filenameFmt.format(startDate)}_${filenameFmt.format(endDate)}.pdf';
                  await Printing.sharePdf(bytes: pdf, filename: filename);
                },
              ),
            ],
          ),
          body: PdfPreview(
            build: (_) => _buildPdf(
              events: events,
              startDate: startDate,
              endDate: endDate,
              categories: categories,
              userName: userName,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  // ── PDF 빌드 ─────────────────────────────────────────────────
  Future<Uint8List> _buildPdf({
    required List<EventModel> events,
    required DateTime startDate,
    required DateTime endDate,
    List<CeremonyType>? categories,
    required String userName,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansKRRegular();
    final boldFont = await PdfGoogleFonts.notoSansKRBold();

    // 기간 필터
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    var filtered =
        events.where((ev) => !ev.date.isBefore(s) && !ev.date.isAfter(e)).toList();

    // 카테고리 필터
    if (categories != null && categories.isNotEmpty) {
      filtered =
          filtered.where((ev) => categories.contains(ev.ceremonyType)).toList();
    }

    filtered.sort((a, b) => a.date.compareTo(b.date));

    final totalIncome =
        filtered.where((ev) => ev.isIncome).fold(0, (s, ev) => s + ev.amount);
    final totalExpense =
        filtered.where((ev) => !ev.isIncome).fold(0, (s, ev) => s + ev.amount);
    final balance = totalIncome - totalExpense;

    // 경조사별 집계
    final Map<CeremonyType, _CerStats> cerStats = {};
    for (final ev in filtered) {
      cerStats[ev.ceremonyType] ??= _CerStats();
      if (ev.isIncome) {
        cerStats[ev.ceremonyType]!.incomeCount++;
        cerStats[ev.ceremonyType]!.incomeTotal += ev.amount;
      } else {
        cerStats[ev.ceremonyType]!.expenseCount++;
        cerStats[ev.ceremonyType]!.expenseTotal += ev.amount;
      }
    }

    final titleFmt = DateFormat('yyyy.MM.dd');
    String reportTitle =
        '${titleFmt.format(startDate)} ~ ${titleFmt.format(endDate)} 경조사 결산 보고서';
    if (categories != null &&
        categories.isNotEmpty &&
        categories.length < CeremonyType.values.length) {
      final cats = categories.map((c) => c.label).join('·');
      reportTitle += ' [$cats]';
    }

    final now = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (ctx) => _buildHeader(reportTitle, userName, now, boldFont),
        footer: (ctx) => _buildFooter(ctx, font),
        build: (ctx) => [
          pw.SizedBox(height: 20),

          // ── 요약 카드 ──────────────────────────────────────
          _summarySection(
              totalIncome, totalExpense, balance, filtered.length, boldFont),
          pw.SizedBox(height: 20),

          // ── 경조사별 통계 ──────────────────────────────────
          if (cerStats.isNotEmpty) ...[
            _sectionTitle('경조사별 통계', boldFont),
            pw.SizedBox(height: 8),
            _cerStatsTable(cerStats, boldFont, font),
            pw.SizedBox(height: 20),
          ],

          // ── 상세 내역 ──────────────────────────────────────
          _sectionTitle('상세 내역 (${filtered.length}건)', boldFont),
          pw.SizedBox(height: 8),
          if (filtered.isEmpty)
            pw.Center(
              child: pw.Text('내역이 없습니다',
                  style: pw.TextStyle(font: font, color: PdfColors.grey)),
            )
          else
            _detailTable(filtered, boldFont, font),
        ],
      ),
    );

    return pdf.save();
  }

  // ── 헤더 ─────────────────────────────────────────────────────
  pw.Widget _buildHeader(
      String title, String userName, String now, pw.Font boldFont) {
    return pw.Column(children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          gradient: const pw.LinearGradient(
            colors: [
              PdfColor.fromInt(0xFF2563EB),
              PdfColor.fromInt(0xFF7C3AED)
            ],
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('💝 경조사 장부',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 11, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(title,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 16, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('$userName · 생성일: $now',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
          ],
        ),
      ),
      pw.SizedBox(height: 4),
    ]);
  }

  // ── 푸터 ─────────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('경조사 장부 앱',
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
        pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
            style:
                pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
      ],
    );
  }

  // ── 요약 섹션 ─────────────────────────────────────────────────
  pw.Widget _summarySection(
      int income, int expense, int balance, int count, pw.Font boldFont) {
    return pw.Row(children: [
      _summaryCard('총 수입', '${_fmt.format(income)}원',
          const PdfColor.fromInt(0xFF10B981), boldFont),
      pw.SizedBox(width: 8),
      _summaryCard('총 지출', '${_fmt.format(expense)}원',
          const PdfColor.fromInt(0xFFEF4444), boldFont),
      pw.SizedBox(width: 8),
      _summaryCard(
          '잔액',
          '${balance >= 0 ? '+' : ''}${_fmt.format(balance)}원',
          balance >= 0
              ? const PdfColor.fromInt(0xFF2563EB)
              : const PdfColor.fromInt(0xFFEF4444),
          boldFont),
      pw.SizedBox(width: 8),
      _summaryCard(
          '총 건수', '$count건', const PdfColor.fromInt(0xFF7C3AED), boldFont),
    ]);
  }

  pw.Widget _summaryCard(
      String label, String value, PdfColor color, pw.Font boldFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor(color.red, color.green, color.blue, 0.1),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(
            color: PdfColor(color.red, color.green, color.blue, 0.3),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style:
                    pw.TextStyle(font: boldFont, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  // ── 섹션 타이틀 ──────────────────────────────────────────────
  pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Row(children: [
      pw.Container(
        width: 4,
        height: 16,
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF2563EB),
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 14)),
    ]);
  }

  // ── 경조사별 통계 테이블 ──────────────────────────────────────
  pw.Widget _cerStatsTable(
      Map<CeremonyType, _CerStats> stats, pw.Font boldFont, pw.Font font) {
    final headers = ['경조사', '수입 건수', '수입 금액', '지출 건수', '지출 금액'];
    final rows = stats.entries
        .map((e) => [
              '${e.key.emoji} ${e.key.label}',
              '${e.value.incomeCount}건',
              '${_fmt.format(e.value.incomeTotal)}원',
              '${e.value.expenseCount}건',
              '${_fmt.format(e.value.expenseTotal)}원',
            ])
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(h,
                        style: pw.TextStyle(font: boldFont, fontSize: 9)),
                  ))
              .toList(),
        ),
        ...rows.map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: pw.Text(cell,
                            style: pw.TextStyle(font: font, fontSize: 9)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  // ── 상세 내역 테이블 ──────────────────────────────────────────
  pw.Widget _detailTable(
      List<EventModel> events, pw.Font boldFont, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
          children: ['날짜', '이름', '경조사', '관계', '금액', '구분', '메모']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 9,
                            color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...events.asMap().entries.map((entry) {
          final i = entry.key;
          final ev = entry.value;
          final isInc = ev.isIncome;
          final bg =
              i.isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFF);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              DateFormat('MM/dd').format(ev.date),
              ev.personName,
              '${ev.ceremonyType.emoji} ${ev.ceremonyType.label}',
              ev.relation.label,
              '${_fmt.format(ev.amount)}원',
              isInc ? '수입' : '지출',
              ev.memo ?? '-',
            ]
                .asMap()
                .entries
                .map((cell) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: pw.Text(
                        cell.value,
                        style: pw.TextStyle(
                          font: cell.key == 4 ? boldFont : font,
                          fontSize: 8,
                          color: cell.key == 4
                              ? (isInc
                                  ? const PdfColor.fromInt(0xFF10B981)
                                  : const PdfColor.fromInt(0xFFEF4444))
                              : PdfColors.grey800,
                        ),
                      ),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }
}

class _CerStats {
  int incomeCount = 0;
  int incomeTotal = 0;
  int expenseCount = 0;
  int expenseTotal = 0;
}
