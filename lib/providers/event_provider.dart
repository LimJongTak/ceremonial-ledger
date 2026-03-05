import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/db_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final filterYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final filterMonthProvider = StateProvider<int?>((ref) => DateTime.now().month);

// Firestore 실시간 스트림
final allEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return FirestoreService.instance.watchEvents(userId);
});

final eventsByDateProvider = Provider<Map<DateTime, List<EventModel>>>((ref) {
  final events = ref.watch(allEventsProvider).valueOrNull ?? [];
  final map = <DateTime, List<EventModel>>{};
  for (final e in events) {
    final key = DateTime(e.date.year, e.date.month, e.date.day);
    map.putIfAbsent(key, () => []).add(e);
  }
  return map;
});

final selectedDayEventsProvider = Provider<List<EventModel>>((ref) {
  final sel = ref.watch(selectedDateProvider);
  final map = ref.watch(eventsByDateProvider);
  return map[DateTime(sel.year, sel.month, sel.day)] ?? [];
});

final ledgerSummaryProvider = Provider<LedgerSummary>((ref) {
  final all = ref.watch(allEventsProvider).valueOrNull ?? [];
  final year = ref.watch(filterYearProvider);
  final month = ref.watch(filterMonthProvider);
  final filtered = all
      .where((e) =>
          e.date.year == year && (month == null || e.date.month == month))
      .toList();
  return LedgerSummary.fromEvents(filtered);
});

class EventNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addEvent(EventModel event) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = await AsyncValue.guard(() async {
      await db.saveEvent(event);
      await FirestoreService.instance.saveEvent(event, userId);
      if (event.date.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleEventNotifications(event);
      }
      final allEvents = ref.read(allEventsProvider).valueOrNull ?? [];
      await HomeWidgetService.instance.updateWidget(allEvents);
    });
  }

  Future<void> deleteEvent(int id, {String? firestoreId}) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserIdProvider);
    state = await AsyncValue.guard(() async {
      // 로컬 삭제
      await db.deleteEvent(id);
      // Firestore 삭제
      if (userId != null && firestoreId != null) {
        await FirestoreService.instance.deleteEvent(userId, firestoreId);
      }
      final allEvents = ref.read(allEventsProvider).valueOrNull ?? [];
      await HomeWidgetService.instance.updateWidget(allEvents);
    });
  }
}

final eventNotifierProvider =
    AsyncNotifierProvider<EventNotifier, void>(() => EventNotifier());
