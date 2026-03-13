import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';

class ExcelTemplateService {
  ExcelTemplateService._();
  static final instance = ExcelTemplateService._();

  // ─── 양식 다운로드 ────────────────────────────────────────────
  Future<String?> downloadTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['경조사_장부'];
      excel.delete('Sheet1');

      // 헤더 스타일
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#1A73E8'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontSize: 11,
      );

      final subHeaderStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
        fontColorHex: ExcelColor.fromHexString('#1A1A2E'),
        fontSize: 10,
      );

      // 제목 행
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('경조사 장부 입력 양식');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#1A73E8'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // 안내 행
      sheet.merge(
        CellIndex.indexByString('A2'),
        CellIndex.indexByString('H2'),
      );
      final guideCell = sheet.cell(CellIndex.indexByString('A2'));
      guideCell.value = TextCellValue(
          '※ 날짜: YYYY-MM-DD 형식 | 금액: 숫자만 입력 | 수입/지출: 수입 또는 지출 | 경조사/관계: 아래 목록 참고');
      guideCell.cellStyle = CellStyle(
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('#666666'),
        backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      );

      // 컬럼 헤더
      final headers = ['날짜', '이름', '경조사', '관계', '금액', '수입/지출', '메모', ''];
      for (var i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // 예시 데이터 3행
      final examples = [
        ['2024-03-15', '홍길동', '결혼', '친구', '50000', '지출', '결혼 축의금'],
        ['2024-03-20', '김철수', '부고', '직장', '30000', '지출', '조의금'],
        ['2024-04-01', '이영희', '생일', '가족', '100000', '수입', '생일 선물 받음'],
      ];

      for (var r = 0; r < examples.length; r++) {
        for (var c = 0; c < examples[r].length; c++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 3));
          cell.value = TextCellValue(examples[r][c]);
          cell.cellStyle = CellStyle(
            fontSize: 10,
            fontColorHex: ExcelColor.fromHexString('#999999'),
          );
        }
      }

      // 빈 입력 행 20개
      for (var r = 6; r < 26; r++) {
        for (var c = 0; c < 7; c++) {
          final cell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
          cell.cellStyle = CellStyle(fontSize: 10);
        }
      }

      // 참고 목록 (우측)
      const refStartCol = 9; // const로 변경

      // 경조사 목록
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: refStartCol, rowIndex: 2))
        ..value = TextCellValue('경조사 목록')
        ..cellStyle = subHeaderStyle;
      final ceremonies = ['결혼', '부고', '돌잔치', '생일', '졸업', '집들이', '승진', '기타'];
      for (var i = 0; i < ceremonies.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: refStartCol, rowIndex: i + 3))
            .value = TextCellValue(ceremonies[i]);
      }

      // 관계 목록
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: refStartCol + 1, rowIndex: 2))
        ..value = TextCellValue('관계 목록')
        ..cellStyle = subHeaderStyle;
      final relations = ['가족', '친척', '친구', '직장', '이웃', '기타'];
      for (var i = 0; i < relations.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: refStartCol + 1, rowIndex: i + 3))
            .value = TextCellValue(relations[i]);
      }

      // 컬럼 너비
      sheet.setColumnWidth(0, 14); // 날짜
      sheet.setColumnWidth(1, 12); // 이름
      sheet.setColumnWidth(2, 10); // 경조사
      sheet.setColumnWidth(3, 10); // 관계
      sheet.setColumnWidth(4, 12); // 금액
      sheet.setColumnWidth(5, 10); // 수입/지출
      sheet.setColumnWidth(6, 20); // 메모

      // 저장
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/경조사_장부_양식.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      debugPrint('엑셀 템플릿 생성 오류: $e');
      return null;
    }
  }

  // ─── 엑셀 파일 파싱 ──────────────────────────────────────────
  Future<List<ExcelEntry>> parseUploadedFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final bytes = result.files.first.bytes;
      if (bytes == null) return [];

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.sheets.values.first;
      final rows = sheet.rows;

      final entries = <ExcelEntry>[];

      // 헤더 찾기 (날짜가 있는 행)
      int dataStartRow = 3;
      for (var r = 0; r < rows.length; r++) {
        final firstCell =
            rows[r].isNotEmpty ? rows[r][0]?.value?.toString() ?? '' : '';
        if (firstCell.contains('날짜') || firstCell.contains('date')) {
          dataStartRow = r + 1;
          break;
        }
      }

      for (var r = dataStartRow; r < rows.length; r++) {
        final row = rows[r];
        if (row.isEmpty) continue;

        // ?.trim() → .trim() 으로 수정 (String은 null이 아님)
        final dateStr =
            row.isNotEmpty ? row[0]?.value?.toString().trim() ?? '' : '';
        final name =
            row.length > 1 ? row[1]?.value?.toString().trim() ?? '' : '';
        final ceremonyStr =
            row.length > 2 ? row[2]?.value?.toString().trim() ?? '' : '';
        final relationStr =
            row.length > 3 ? row[3]?.value?.toString().trim() ?? '' : '';
        final amountStr =
            row.length > 4 ? row[4]?.value?.toString().trim() ?? '' : '';
        final typeStr =
            row.length > 5 ? row[5]?.value?.toString().trim() ?? '' : '';
        final memo = row.length > 6 ? row[6]?.value?.toString().trim() : null;

        // 필수값 검사
        if (name.isEmpty || amountStr.isEmpty) continue;

        // 날짜 파싱
        DateTime date;
        try {
          date = DateFormat('yyyy-MM-dd').parse(dateStr);
        } catch (_) {
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }
        }

        // 금액 파싱
        final amount =
            int.tryParse(amountStr.replaceAll(',', '').replaceAll('원', ''));
        if (amount == null || amount <= 0) continue;

        // 경조사/관계/수입지출 파싱
        final ceremony = _parseCeremony(ceremonyStr);
        final relation = _parseRelation(relationStr);
        final eventType =
            typeStr.contains('수입') ? EventType.income : EventType.expense;

        entries.add(ExcelEntry(
          date: date,
          name: name,
          ceremony: ceremony,
          relation: relation,
          amount: amount,
          eventType: eventType,
          memo: (memo == null || memo.isEmpty) ? null : memo,
        ));
      }

      return entries;
    } catch (e) {
      debugPrint('엑셀 파싱 오류: $e');
      return [];
    }
  }

  CeremonyType _parseCeremony(String s) {
    if (s.contains('결혼')) return CeremonyType.wedding;
    if (s.contains('부고') || s.contains('장례')) return CeremonyType.funeral;
    if (s.contains('돌') || s.contains('백일')) return CeremonyType.babyShower;
    if (s.contains('생일')) return CeremonyType.birthday;
    if (s.contains('졸업')) return CeremonyType.graduation;
    if (s.contains('집들이')) return CeremonyType.houseWarming;
    if (s.contains('승진')) return CeremonyType.promotion;
    return CeremonyType.other;
  }

  RelationType _parseRelation(String s) {
    if (s.contains('가족')) return RelationType.family;
    if (s.contains('친척')) return RelationType.relative;
    if (s.contains('친구')) return RelationType.friend;
    if (s.contains('직장') || s.contains('동료')) return RelationType.colleague;
    if (s.contains('이웃')) return RelationType.neighbor;
    return RelationType.other;
  }

  // ─── 데이터 내보내기 ──────────────────────────────────────────
  Future<String?> exportData({
    required List<EventModel> events,
    required DateTime startDate,
    required DateTime endDate,
    List<CeremonyType>? categories,
  }) async {
    try {
      // 기간 필터
      final s = DateTime(startDate.year, startDate.month, startDate.day);
      final e =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      var filtered = events
          .where((ev) => !ev.date.isBefore(s) && !ev.date.isAfter(e))
          .toList();

      // 카테고리 필터
      if (categories != null && categories.isNotEmpty) {
        filtered = filtered
            .where((ev) => categories.contains(ev.ceremonyType))
            .toList();
      }

      filtered.sort((a, b) => a.date.compareTo(b.date));

      final excel = Excel.createExcel();
      final sheet = excel['경조사_장부'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#1A73E8'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontSize: 11,
      );

      // 제목
      final titleFmt = DateFormat('yyyy.MM.dd');
      String titleStr =
          '${titleFmt.format(startDate)} ~ ${titleFmt.format(endDate)} 경조사 결산';
      if (categories != null &&
          categories.isNotEmpty &&
          categories.length < CeremonyType.values.length) {
        titleStr += ' [${categories.map((c) => c.label).join('·')}]';
      }

      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );
      sheet.cell(CellIndex.indexByString('A1'))
        ..value = TextCellValue(titleStr)
        ..cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('#1A73E8'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );

      // 헤더 행
      final headers = ['날짜', '이름', '경조사', '관계', '금액', '수입/지출', '메모'];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          ..value = TextCellValue(headers[i])
          ..cellStyle = headerStyle;
      }

      // 데이터 행
      final dateFmt2 = DateFormat('yyyy-MM-dd');
      final fmt = NumberFormat('#,###');
      for (var r = 0; r < filtered.length; r++) {
        final ev = filtered[r];
        final isIncome = ev.isIncome;
        final rowStyle = CellStyle(
          fontSize: 10,
          backgroundColorHex: r.isEven
              ? ExcelColor.fromHexString('#FFFFFF')
              : ExcelColor.fromHexString('#F8FAFF'),
        );
        final amountStyle = CellStyle(
          fontSize: 10,
          bold: true,
          fontColorHex: isIncome
              ? ExcelColor.fromHexString('#10B981')
              : ExcelColor.fromHexString('#EF4444'),
          backgroundColorHex: r.isEven
              ? ExcelColor.fromHexString('#FFFFFF')
              : ExcelColor.fromHexString('#F8FAFF'),
        );

        final rowData = [
          dateFmt2.format(ev.date),
          ev.personName,
          '${ev.ceremonyType.emoji} ${ev.ceremonyType.label}',
          ev.relation.label,
          '${fmt.format(ev.amount)}원',
          ev.eventType.label,
          ev.memo ?? '',
        ];
        for (var c = 0; c < rowData.length; c++) {
          sheet
              .cell(
                  CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 2))
            ..value = TextCellValue(rowData[c])
            ..cellStyle = c == 4 ? amountStyle : rowStyle;
        }
      }

      // 합계 행
      final totalRow = filtered.length + 2;
      final incomeTotal = filtered
          .where((ev) => ev.isIncome)
          .fold(0, (s, ev) => s + ev.amount);
      final expenseTotal = filtered
          .where((ev) => !ev.isIncome)
          .fold(0, (s, ev) => s + ev.amount);

      final summaryStyle = CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
      );
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRow),
      );
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
        ..value = TextCellValue('합계 (${filtered.length}건)')
        ..cellStyle = summaryStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow),
      );
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow))
        ..value = TextCellValue(
            '수입: ${fmt.format(incomeTotal)}원 / 지출: ${fmt.format(expenseTotal)}원')
        ..cellStyle = summaryStyle;

      // 컬럼 너비
      sheet.setColumnWidth(0, 14);
      sheet.setColumnWidth(1, 12);
      sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 10);
      sheet.setColumnWidth(4, 16);
      sheet.setColumnWidth(5, 10);
      sheet.setColumnWidth(6, 20);

      // 저장
      final dir = await getApplicationDocumentsDirectory();
      final filenameFmt = DateFormat('yyyyMMdd');
      final filename =
          '경조사결산_${filenameFmt.format(startDate)}_${filenameFmt.format(endDate)}.xlsx';
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      debugPrint('엑셀 내보내기 오류: $e');
      return null;
    }
  }

  Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}

class ExcelEntry {
  final DateTime date;
  final String name;
  final CeremonyType ceremony;
  final RelationType relation;
  final int amount;
  final EventType eventType;
  final String? memo;
  bool isSelected;

  ExcelEntry({
    required this.date,
    required this.name,
    required this.ceremony,
    required this.relation,
    required this.amount,
    required this.eventType,
    this.memo,
    this.isSelected = true,
  });
}
