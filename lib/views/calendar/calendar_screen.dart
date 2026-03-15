import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/kakao_share_service.dart';
import 'event_bottom_sheet.dart';
// TODO: OCR 기능 준비 중 - import '../calendar/ocr_register_screen.dart';
import '../export/excel_import_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDateProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final eventsByDate = ref.watch(eventsByDateProvider);
    final selectedEvents = ref.watch(selectedDayEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('경조사 캘린더'),
        actions: [
          // TODO: OCR 기능 준비 중 - 카메라 일괄 등록 버튼
          IconButton(
            // ← 이 버튼 추가
            icon: const Icon(Icons.table_view_outlined),
            tooltip: '엑셀로 일괄 등록',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExcelImportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 캘린더
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar<EventModel>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              eventLoader: (day) =>
                  eventsByDate[DateTime(day.year, day.month, day.day)] ?? [],
              onDaySelected: (sel, foc) {
                ref.read(selectedDateProvider.notifier).state = sel;
                ref.read(focusedDayProvider.notifier).state = foc;
              },
              onPageChanged: (foc) =>
                  ref.read(focusedDayProvider.notifier).state = foc,
              locale: 'ko_KR',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 수입=파란점, 지출=빨간점 마커
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  final hasIn = events.any((e) => e.isIncome);
                  final hasEx = events.any((e) => !e.isIncome);
                  final hasRecurring = events.any((e) => e.isRecurring);
                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasIn)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasEx)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                        // 반복 이벤트: 주황 테두리 원
                        if (hasRecurring)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 1.5),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 날짜 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDay.month}월 ${selectedDay.day}일',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedEvents.length}건',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 이벤트 목록
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 52,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '이 날의 경조사 내역이 없습니다',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: selectedEvents.length,
                    itemBuilder: (ctx, i) => EventCard(
                      event: selectedEvents[i],
                      onTap: () =>
                          _openSheet(ctx, ref, selectedDay, selectedEvents[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context, ref, selectedDay, null),
        icon: const Icon(Icons.add),
        label: const Text('내역 추가'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openSheet(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    EventModel? event,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EventBottomSheet(initialDate: date, eventToEdit: event),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  const EventCard({super.key, required this.event, this.onTap});

  bool get _isToday {
    final now = DateTime.now();
    return event.date.year == now.year &&
        event.date.month == now.month &&
        event.date.day == now.day;
  }

  Future<void> _shareEvent(BuildContext context) async {
    final error = await KakaoShareService.instance.shareEvent(event);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카카오톡 공유에 실패했습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openNavigation(BuildContext context) async {
    final location = event.location;
    if (location == null || location.isEmpty) return;

    final encoded = Uri.encodeComponent(location);
    final kakaoUri = Uri.parse('kakaomap://search?q=$encoded');

    if (await canLaunchUrl(kakaoUri)) {
      await launchUrl(kakaoUri);
    } else {
      // 카카오맵 앱 미설치 시 웹 폴백
      final webUri = Uri.parse('https://map.kakao.com/?q=$encoded');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = event.isIncome;
    final showNavBtn = _isToday && event.location != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: inc ? const Color(0xFF1A73E8) : const Color(0xFFE53935),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    event.displayEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            event.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (event.isRecurring) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded,
                                      size: 10, color: Color(0xFF2563EB)),
                                  SizedBox(width: 2),
                                  Text('매년',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          '${event.displayLabel} · '
                          '${event.relation.label}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        // 장소 표시
                        if (event.location != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.location_on_rounded,
                                size: 11, color: Colors.grey[400]),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[400]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    event.formattedAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: inc
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ),

            // ── 하단 버튼 (카카오톡 공유 / 길찾기) ──────────
            GestureDetector(
              // 하단 버튼 탭이 카드 onTap으로 전파되지 않도록 차단
              onTap: () {},
              child: Column(
                children: [
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withValues(alpha: 0.12)),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // 카카오톡 공유 버튼 (항상 표시)
                        Expanded(
                          child: InkWell(
                            onTap: () => _shareEvent(context),
                            borderRadius: BorderRadius.only(
                              bottomLeft: const Radius.circular(12),
                              bottomRight: showNavBtn
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/kakaotalk-icon.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '카카오톡 공유',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 길찾기 버튼 (당일 + 장소 있을 때)
                        if (showNavBtn) ...[
                          VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Colors.grey.withValues(alpha: 0.12)),
                          Expanded(
                            child: InkWell(
                              onTap: () => _openNavigation(context),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.navigation_rounded,
                                        size: 15, color: Colors.blue[600]),
                                    const SizedBox(width: 5),
                                    Text(
                                      '카카오맵 길찾기',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
