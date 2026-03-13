import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/db_service.dart';
import '../services/firestore_service.dart';
import '../services/family_service.dart';
import 'auth_provider.dart';
import 'family_provider.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final filterYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final filterMonthProvider = StateProvider<int?>((ref) => DateTime.now().month);

// 가족 여부에 따라 적절한 컬렉션에서 이벤트 스트림 제공
final allEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final family = ref.watch(familyProvider).valueOrNull;
  if (family != null) {
    return FamilyService.instance.watchFamilyEvents(family.id);
  }
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

    final family = ref.read(familyProvider).valueOrNull;

    state = await AsyncValue.guard(() async {
      await db.saveEvent(event);
      if (family != null) {
        // 가족 공유 컬렉션에 저장
        await FamilyService.instance
            .saveFamilyEvent(event, family.id, userId);
      } else {
        // 개인 컬렉션에 저장
        await FirestoreService.instance.saveEvent(event, userId);
      }
      if (event.isRecurring) {
        await NotificationService.instance
            .scheduleRecurringNotifications(event);
      } else if (event.date.isAfter(DateTime.now())) {
        await NotificationService.instance
            .scheduleEventNotifications(event);
      }
      final allEvents = ref.read(allEventsProvider).valueOrNull ?? [];
      await HomeWidgetService.instance.updateWidget(allEvents);
    });
  }

  Future<void> deleteEvent(int id, {String? firestoreId}) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserIdProvider);
    final family = ref.read(familyProvider).valueOrNull;

    state = await AsyncValue.guard(() async {
      await db.deleteEvent(id);
      if (firestoreId != null) {
        if (family != null) {
          // 가족 공유 컬렉션에서 삭제
          await FamilyService.instance
              .deleteFamilyEvent(family.id, firestoreId);
        } else if (userId != null) {
          // 개인 컬렉션에서 삭제
          await FirestoreService.instance.deleteEvent(userId, firestoreId);
        }
      }
      final allEvents = ref.read(allEventsProvider).valueOrNull ?? [];
      await HomeWidgetService.instance.updateWidget(allEvents);
    });
  }
}

final eventNotifierProvider =
    AsyncNotifierProvider<EventNotifier, void>(() => EventNotifier());
