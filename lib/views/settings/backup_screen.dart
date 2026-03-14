import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/backup_service.dart';
import '../common/app_theme.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  List<DriveFileInfo> _driveFiles = [];
  bool _driveListLoading = false;

  void _setStatus(String msg, {bool success = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _isSuccess = success;
    });
  }

  void _clearStatus() => setState(() => _message = null);

  // ── 백업: Google Drive ───────────────────────────────────────
  Future<void> _backupToGoogleDrive(
      String userId, List<EventModel> events) async {
    setState(() => _isLoading = true);
    _clearStatus();
    try {
      final data =
          await BackupService.instance.createBackup(userId, events);
      await BackupService.instance.uploadToGoogleDrive(data);
      _setStatus(
          '✅ Google 드라이브에 백업이 완료되었습니다.\n(Google 드라이브 > 오고가고 백업 폴더)',
          success: true);
    } catch (e) {
      _setStatus('❌ Google 드라이브 백업 실패: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 백업: 로컬 파일 (Naver MyBox 등) ────────────────────────
  Future<void> _backupToLocalFile(
      String userId, List<EventModel> events) async {
    setState(() => _isLoading = true);
    _clearStatus();
    try {
      final data =
          await BackupService.instance.createBackup(userId, events);
      final file = await BackupService.instance.exportToFile(data);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '오고가고 경조사 데이터 백업',
        text: '오고가고 앱 경조사 장부 백업 파일입니다.',
      );
    } catch (e) {
      _setStatus('❌ 파일 저장 실패: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 복원: Google Drive 목록 조회 ────────────────────────────
  Future<void> _loadDriveBackups() async {
    setState(() {
      _driveListLoading = true;
      _driveFiles = [];
    });
    try {
      final files = await BackupService.instance.listGoogleDriveBackups();
      if (!mounted) return;
      setState(() => _driveFiles = files);
      if (files.isEmpty) {
        _setStatus('Google 드라이브에 저장된 백업이 없습니다.');
      }
    } catch (e) {
      _setStatus('❌ 백업 목록 조회 실패: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _driveListLoading = false);
    }
  }

  // ── 복원: Drive 파일 선택 후 복원 ───────────────────────────
  Future<void> _restoreFromDrive(
    String fileId,
    String fileName,
    String userId,
    List<EventModel> events,
  ) async {
    final confirmed = await _confirmRestore(fileName);
    if (!confirmed) return;

    setState(() => _isLoading = true);
    _clearStatus();
    try {
      final data =
          await BackupService.instance.downloadFromGoogleDrive(fileId);
      await BackupService.instance.restoreBackup(data, userId, events);
      setState(() => _driveFiles = []);
      _setStatus(
          '✅ 복원 완료! (${data.events.length}건)\n앱을 재시작하면 데이터가 반영됩니다.',
          success: true);
    } catch (e) {
      _setStatus('❌ 복원 실패: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 복원: 로컬 파일에서 ──────────────────────────────────────
  Future<void> _restoreFromFile(
      String userId, List<EventModel> events) async {
    BackupData? data;
    try {
      data = await BackupService.instance.importFromFile();
    } catch (e) {
      _setStatus('❌ 파일을 읽을 수 없습니다: ${_errorMessage(e)}');
      return;
    }
    if (data == null) return; // 사용자가 파일 선택 취소

    final confirmed = await _confirmRestore('선택한 파일');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    _clearStatus();
    try {
      await BackupService.instance.restoreBackup(data, userId, events);
      _setStatus(
          '✅ 복원 완료! (${data.events.length}건)\n앱을 재시작하면 데이터가 반영됩니다.',
          success: true);
    } catch (e) {
      _setStatus('❌ 복원 실패: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 복원 확인 다이얼로그 ─────────────────────────────────────
  Future<bool> _confirmRestore(String sourceName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '⚠️ 복원 확인',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '$sourceName에서 복원하면\n현재 모든 데이터가 삭제되고\n백업 데이터로 교체됩니다.\n\n정말 복원하시겠습니까?',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('복원하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('취소')) return 'Google 로그인이 취소되었습니다.';
    if (msg.contains('network') || msg.contains('SocketException')) {
      return '네트워크 연결을 확인하세요.';
    }
    return msg.length > 80 ? '${msg.substring(0, 80)}...' : msg;
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final events = ref.watch(allEventsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '데이터 백업 · 복원',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 18),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 안내 카드 ───────────────────────────────────
                _InfoCard(eventCount: events.length),
                const SizedBox(height: 20),

                // ── 백업 카드 ───────────────────────────────────
                const _SectionTitle(title: '백업하기', icon: Icons.cloud_upload_outlined),
                const SizedBox(height: 10),
                _ActionCard(
                  children: [
                    _ActionTile(
                      icon: Icons.add_to_drive_rounded,
                      iconColor: const Color(0xFF1A73E8),
                      title: 'Google 드라이브에 백업',
                      subtitle: '드라이브 > 오고가고 백업 폴더에 저장',
                      onTap: userId == null
                          ? null
                          : () => _backupToGoogleDrive(userId, events),
                    ),
                    const _Divider(),
                    _ActionTile(
                      icon: Icons.save_alt_rounded,
                      iconColor: AppTheme.secondary,
                      title: '파일로 저장',
                      subtitle: 'Naver MyBox, 카카오드라이브 등 공유',
                      onTap: userId == null
                          ? null
                          : () => _backupToLocalFile(userId, events),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 복원 카드 ───────────────────────────────────
                const _SectionTitle(
                    title: '복원하기', icon: Icons.cloud_download_outlined),
                const SizedBox(height: 10),
                _ActionCard(
                  children: [
                    _ActionTile(
                      icon: Icons.add_to_drive_rounded,
                      iconColor: const Color(0xFF1A73E8),
                      title: 'Google 드라이브에서 복원',
                      subtitle: '저장된 백업 목록에서 선택',
                      onTap: userId == null ? null : _loadDriveBackups,
                    ),
                    const _Divider(),
                    _ActionTile(
                      icon: Icons.folder_open_rounded,
                      iconColor: AppTheme.gold,
                      title: '파일에서 복원',
                      subtitle: '.json 백업 파일 선택',
                      onTap: userId == null
                          ? null
                          : () => _restoreFromFile(userId, events),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Drive 백업 목록 ──────────────────────────────
                if (_driveListLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_driveFiles.isNotEmpty) ...[
                  const _SectionTitle(
                      title: '백업 목록 선택',
                      icon: Icons.list_alt_rounded),
                  const SizedBox(height: 10),
                  _DriveFileList(
                    files: _driveFiles,
                    onSelect: (file) => userId == null
                        ? null
                        : _restoreFromDrive(
                            file.id, file.displayName, userId, events),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 결과 메시지 ──────────────────────────────────
                if (_message != null) ...[
                  _StatusCard(message: _message!, isSuccess: _isSuccess),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),

          // ── 로딩 오버레이 ────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('처리 중...', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 안내 카드 ──────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final int eventCount;
  const _InfoCard({required this.eventCount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 저장된 데이터: $eventCount건',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• 백업: 경조사 내역, 예산, 알림 설정 포함\n'
                  '• 사진 파일은 기기에 종속되어 백업에서 제외됩니다\n'
                  '• 복원 시 현재 데이터가 모두 삭제됩니다',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ]),
      );
}

// ── 섹션 타이틀 ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3),
        ),
      ]);
}

// ── 액션 카드 컨테이너 ─────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final List<Widget> children;
  const _ActionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: children),
      );
}

// ── 액션 타일 ──────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback? onTap;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onTap != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onTap != null ? AppTheme.textHint : AppTheme.textHint.withValues(alpha: 0.3),
              size: 20,
            ),
          ]),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 70, color: Color(0xFFF1F5F9));
}

// ── Google Drive 백업 목록 ─────────────────────────────────────
class _DriveFileList extends StatelessWidget {
  final List<DriveFileInfo> files;
  final void Function(DriveFileInfo file)? onSelect;
  const _DriveFileList({required this.files, this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: List.generate(files.length, (i) {
            final file = files[i];
            return Column(children: [
              InkWell(
                onTap: () => onSelect?.call(file),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded,
                          color: Color(0xFF1A73E8), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.displayName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          if (file.createdTime != null)
                            Text(
                              file.createdTime!.toLocal().toString().substring(0, 16),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.restore_rounded,
                        color: AppTheme.primary, size: 20),
                  ]),
                ),
              ),
              if (i < files.length - 1)
                const Divider(
                    height: 1, indent: 70, color: Color(0xFFF1F5F9)),
            ]);
          }),
        ),
      );
}

// ── 상태 메시지 카드 ───────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final String message;
  final bool isSuccess;
  const _StatusCard({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppTheme.income : AppTheme.expense;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(
            fontSize: 13, color: color, height: 1.5),
      ),
    );
  }
}
