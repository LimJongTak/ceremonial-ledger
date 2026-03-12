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
