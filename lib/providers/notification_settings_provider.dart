import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_settings.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() =>
      NotificationSettingsService.instance.load();

  Future<void> save(NotificationSettings settings) async {
    state = AsyncData(settings);
    await NotificationSettingsService.instance.save(settings);
  }

  Future<void> resetToDefaults() => save(NotificationSettings.defaults());
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
