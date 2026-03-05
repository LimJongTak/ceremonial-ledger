import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import 'event_bottom_sheet.dart';
import 'ocr_register_screen.dart';
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
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: '카메라로 일괄 등록',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OcrRegisterScreen()),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final inc = event.isIncome;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Text(
              event.ceremonyType.emoji,
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.personName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.ceremonyType.label} · '
                    '${event.relation.label}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Text(
              event.formattedAmount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: inc ? const Color(0xFF1A73E8) : const Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
