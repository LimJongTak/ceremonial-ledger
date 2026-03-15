import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 전화번호부에서 이름 목록을 불러옵니다.
/// 권한이 없거나 실패하면 빈 목록을 반환합니다.
final contactNamesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return [];
    final contacts = await FlutterContacts.getContacts(
      withProperties: false,
      withPhoto: false,
    );
    final names = contacts
        .map((c) => c.displayName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  } catch (_) {
    return [];
  }
});

/// 이름 → 생일 DateTime 맵 (연락처 생일 자동완성용)
final contactBirthdaysProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  try {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return {};
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );
    final Map<String, DateTime> result = {};
    final now = DateTime.now();
    for (final c in contacts) {
      final name = c.displayName.trim();
      if (name.isEmpty) continue;
      try {
        final birthdayEvent = c.events
            .where((e) => e.label == EventLabel.birthday)
            .firstOrNull;
        if (birthdayEvent == null) continue;
        final year = birthdayEvent.year ?? now.year;
        result[name] = DateTime(year, birthdayEvent.month, birthdayEvent.day);
      } catch (_) {
        continue;
      }
    }
    return result;
  } catch (_) {
    return {};
  }
});
