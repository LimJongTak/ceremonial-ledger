import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../models/notification_settings.dart';
import 'db_service.dart';
import 'firestore_service.dart';
import 'notification_settings_service.dart';

// ── 백업 파일 구조 ──────────────────────────────────────────────
class BackupData {
  final int version;
  final String createdAt;
  final List<Map<String, dynamic>> events;
  final int budget;
  final Map<String, dynamic> notificationSettings;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.events,
    required this.budget,
    required this.notificationSettings,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'appName': '오고가고',
        'createdAt': createdAt,
        'events': events,
        'budget': budget,
        'notificationSettings': notificationSettings,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: (json['version'] as int?) ?? 1,
      createdAt: (json['createdAt'] as String?) ?? '',
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      budget: (json['budget'] as int?) ?? 0,
      notificationSettings: Map<String, dynamic>.from(
          json['notificationSettings'] as Map? ?? {}),
    );
  }
}

// ── Google Drive 파일 정보 ───────────────────────────────────────
class DriveFileInfo {
  final String id;
  final String name;
  final DateTime? createdTime;

  const DriveFileInfo({
    required this.id,
    required this.name,
    this.createdTime,
  });

  /// 파일명에서 날짜 포맷팅 (ogogo_backup_20240101_120000.json → 2024-01-01 12:00)
  String get displayName {
    try {
      // ogogo_backup_YYYYMMDD_HHmmss.json
      final raw = name
          .replaceFirst('ogogo_backup_', '')
          .replaceFirst('.json', '');
      final parts = raw.split('_');
      if (parts.length >= 2) {
        final date = parts[0]; // YYYYMMDD
        final time = parts[1]; // HHmmss
        final y = date.substring(0, 4);
        final m = date.substring(4, 6);
        final d = date.substring(6, 8);
        final h = time.substring(0, 2);
        final min = time.substring(2, 4);
        return '$y-$m-$d $h:$min 백업';
      }
    } catch (_) {}
    return name;
  }
}

// ── BackupService ────────────────────────────────────────────────
class BackupService {
  BackupService._();
  static final instance = BackupService._();

  static const _folderName = '오고가고 백업';
  static const _filePrefix = 'ogogo_backup_';

  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // ── 백업 데이터 생성 ─────────────────────────────────────────
  Future<BackupData> createBackup(
      String userId, List<EventModel> currentEvents) async {
    // 이벤트: 로컬 파일 경로(photos)는 기기별로 달라 저장하지 않음
    final eventsJson = currentEvents.map(_eventToJson).toList();

    // 예산
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getInt('monthly_budget') ?? 0;

    // 알림 설정
    final notifSettings = await NotificationSettingsService.instance.load();

    return BackupData(
      version: 1,
      createdAt: DateTime.now().toIso8601String(),
      events: eventsJson,
      budget: budget,
      notificationSettings: notifSettings.toJson(),
    );
  }

  // ── 백업 복원 ────────────────────────────────────────────────
  Future<void> restoreBackup(
    BackupData data,
    String userId,
    List<EventModel> currentEvents,
  ) async {
    // 1. Firestore 기존 데이터 전체 삭제
    await FirestoreService.instance.deleteAllUserEvents(userId);

    // 2. Drift 로컬 DB 기존 데이터 전체 삭제
    await db.deleteAllEvents(userId);

    // 3. Firestore 일괄 추가
    if (data.events.isNotEmpty) {
      final firestoreData = data.events.map((e) {
        final date = DateTime.parse(e['date'] as String);
        final relation = RelationType.values.byName(e['relation'] as String);
        final ceremonyType =
            CeremonyType.values.byName(e['ceremonyType'] as String);
        final eventType = EventType.values.byName(e['eventType'] as String);
        return {
          'date': Timestamp.fromDate(date),
          'personName': e['personName'] as String,
          'relation': relation.index,
          'ceremonyType': ceremonyType.index,
          'amount': e['amount'] as int,
          'eventType': eventType.index,
          'memo': e['memo'],
          'userId': userId,
          'isRecurring': (e['isRecurring'] as bool?) ?? false,
          'location': e['location'] as String?,
          'photos': <String>[], // 로컬 사진 경로는 복원 불가
        };
      }).toList();
      await FirestoreService.instance.batchAddEvents(firestoreData, userId);
    }

    // 4. 예산 복원
    final prefs = await SharedPreferences.getInstance();
    if (data.budget > 0) {
      await prefs.setInt('monthly_budget', data.budget);
    } else {
      await prefs.remove('monthly_budget');
    }

    // 5. 알림 설정 복원
    if (data.notificationSettings.isNotEmpty) {
      try {
        final settings =
            NotificationSettings.fromJson(data.notificationSettings);
        await NotificationSettingsService.instance.save(settings);
      } catch (e) {
        debugPrint('알림 설정 복원 오류: $e');
      }
    }
  }

  // ── 로컬 파일로 내보내기 (공유용) ───────────────────────────
  Future<File> exportToFile(BackupData data) async {
    final dir = await getTemporaryDirectory();
    final timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/$_filePrefix$timestamp.json');
    await file.writeAsString(jsonEncode(data.toJson()), encoding: utf8);
    return file;
  }

  // ── 로컬 파일에서 불러오기 ───────────────────────────────────
  Future<BackupData?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;

    final content = await File(path).readAsString(encoding: utf8);
    final json = jsonDecode(content) as Map<String, dynamic>;
    return BackupData.fromJson(json);
  }

  // ── Google Drive: 업로드 ─────────────────────────────────────
  Future<void> uploadToGoogleDrive(BackupData data) async {
    final authClient = await _getAuthClient();
    try {
      final driveApi = drive.DriveApi(authClient);
      final folderId = await _getOrCreateFolder(driveApi);

      final timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '$_filePrefix$timestamp.json';
      final content = jsonEncode(data.toJson());
      final bytes = utf8.encode(content);

      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = 'application/json';

      await driveApi.files.create(
        fileMetadata,
        uploadMedia: drive.Media(
          Stream.value(bytes),
          bytes.length,
        ),
      );
    } finally {
      authClient.close();
    }
  }

  // ── Google Drive: 백업 목록 조회 ────────────────────────────
  Future<List<DriveFileInfo>> listGoogleDriveBackups() async {
    final authClient = await _getAuthClient();
    try {
      final driveApi = drive.DriveApi(authClient);
      final folderId = await _getOrCreateFolder(driveApi);

      final result = await driveApi.files.list(
        q: "name contains '$_filePrefix' "
            "and '$folderId' in parents "
            "and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, createdTime)',
      );

      return (result.files ?? []).map((f) {
        return DriveFileInfo(
          id: f.id ?? '',
          name: f.name ?? '',
          createdTime: f.createdTime,
        );
      }).toList();
    } finally {
      authClient.close();
    }
  }

  // ── Google Drive: 다운로드 ───────────────────────────────────
  Future<BackupData> downloadFromGoogleDrive(String fileId) async {
    final authClient = await _getAuthClient();
    try {
      final driveApi = drive.DriveApi(authClient);
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = <int>[];
      await for (final chunk in response.stream) {
        chunks.addAll(chunk);
      }

      final content = utf8.decode(chunks);
      final json = jsonDecode(content) as Map<String, dynamic>;
      return BackupData.fromJson(json);
    } finally {
      authClient.close();
    }
  }

  // ── Private: Google 인증 클라이언트 ─────────────────────────
  Future<dynamic> _getAuthClient() async {
    var account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) throw Exception('Google 로그인이 취소되었습니다.');

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception('Google 인증에 실패했습니다.');
    return client;
  }

  // ── Private: Drive 폴더 조회/생성 ───────────────────────────
  Future<String> _getOrCreateFolder(drive.DriveApi driveApi) async {
    final result = await driveApi.files.list(
      q: "name = '$_folderName' "
          "and mimeType = 'application/vnd.google-apps.folder' "
          "and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder);
    return created.id!;
  }

  // ── Private: EventModel → JSON ───────────────────────────────
  Map<String, dynamic> _eventToJson(EventModel e) => {
        'date': e.date.toIso8601String(),
        'personName': e.personName,
        'relation': e.relation.name,
        'ceremonyType': e.ceremonyType.name,
        'amount': e.amount,
        'eventType': e.eventType.name,
        'memo': e.memo,
        'isRecurring': e.isRecurring,
        'location': e.location,
        // 사진 경로는 로컬 기기에 종속되므로 백업에 포함하지 않음
      };
}
