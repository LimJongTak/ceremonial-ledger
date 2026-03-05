import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  static const _appGroupId = 'com.yourcompany.ceremonial_ledger';
  static const _iOSWidgetName = 'CeremonialLedgerWidget';
  static const _androidWidgetName =
      'com.yourcompany.ceremonial_ledger.HomeWidgetProvider';

  final _fmt = NumberFormat('#,###');

  // ── 초기화 ─────────────────────────────────────────────────
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    debugPrint('✅ HomeWidgetService 초기화 완료');
  }

  // ── 위젯 데이터 업데이트 ──────────────────────────────────
  Future<void> updateWidget(List<EventModel> events) async {
    try {
      final now = DateTime.now();
      final thisMonth = events
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();

      final income = thisMonth
          .where((e) => e.isIncome)
          .fold<int>(0, (s, e) => s + e.amount);
      final expense = thisMonth
          .where((e) => !e.isIncome)
          .fold<int>(0, (s, e) => s + e.amount);
      final balance = income - expense;

      // 다가오는 일정 (30일 이내)
      final upcoming = events
          .where((e) =>
              e.date.isAfter(now) &&
              e.date.isBefore(now.add(const Duration(days: 30))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      String upcomingText = '다가오는 일정 없음';
      if (upcoming.isNotEmpty) {
        final top = upcoming.take(2).toList();
        upcomingText = top.map((e) {
          final d = e.date.difference(now).inDays;
          return 'D-$d ${e.ceremonyType.emoji} ${e.personName}';
        }).join('  ·  ');
      }

      // 데이터 저장
      await HomeWidget.saveWidgetData(
          'widget_balance',
          balance >= 0
              ? '${_fmt.format(balance)}원'
              : '-${_fmt.format(balance.abs())}원');
      await HomeWidget.saveWidgetData(
          'widget_income', '${_fmt.format(income)}원');
      await HomeWidget.saveWidgetData(
          'widget_expense', '${_fmt.format(expense)}원');
      await HomeWidget.saveWidgetData('widget_count', '${thisMonth.length}건');
      await HomeWidget.saveWidgetData('widget_month', '${now.month}월');
      await HomeWidget.saveWidgetData('widget_upcoming', upcomingText);

      // 위젯 갱신
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('✅ 홈 위젯 업데이트 완료');
    } catch (e) {
      debugPrint('❌ 홈 위젯 업데이트 실패: $e');
    }
  }
}
