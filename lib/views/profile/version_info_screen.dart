import 'package:flutter/material.dart';
import '../common/app_theme.dart';

class _VersionEntry {
  final String version;
  final String date;
  final bool isCurrent;
  final List<String> changes;

  const _VersionEntry({
    required this.version,
    required this.date,
    this.isCurrent = false,
    required this.changes,
  });
}

class VersionInfoScreen extends StatelessWidget {
  const VersionInfoScreen({super.key});

  static const _currentVersion = '1.0.0';

  static const _history = [
    _VersionEntry(
      version: '1.0.0',
      date: '2025년 3월',
      isCurrent: true,
      changes: [
        '🎉 오고가고 첫 출시',
        '경조사 장부 기록 및 관리',
        '카카오, 네이버, Google 소셜 로그인',
        '캘린더 뷰 및 통계 화면',
        '엑셀 일괄 등록 및 PDF/엑셀 내보내기',
        '홈 위젯 지원',
        '알림 기능',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('버전 정보')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 앱 아이콘 + 현재 버전 배지
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/app_icon.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '최신 버전 v$_currentVersion',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 업데이트 내역 헤더
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              '업데이트 내역',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3),
            ),
          ),

          ..._history.map((e) => _VersionCard(entry: e)),

          const SizedBox(height: 40),
          const Center(
            child: Text(
              'ⓒ 2025 오고가고 All rights reserved.',
              style:
                  TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final _VersionEntry entry;
  const _VersionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: entry.isCurrent
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 버전 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: entry.isCurrent
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.isCurrent
                        ? AppTheme.primary
                        : AppTheme.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v${entry.version}',
                    style: TextStyle(
                        color:
                            entry.isCurrent ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                if (entry.isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '현재',
                      style: TextStyle(
                          color: AppTheme.income,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  entry.date,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          // 변경사항 목록
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.changes
                  .map((change) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            Expanded(
                              child: Text(
                                change,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
