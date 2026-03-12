import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/notification_settings.dart';

class NotificationSettingsService {
  NotificationSettingsService._();
  static final instance = NotificationSettingsService._();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notification_settings.json');
  }

  Future<NotificationSettings> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return NotificationSettings.defaults();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      debugPrint('NotificationSettingsService.load error: $e');
      return NotificationSettings.defaults();
    }
  }

  Future<void> save(NotificationSettings settings) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('NotificationSettingsService.save error: $e');
    }
  }
}
