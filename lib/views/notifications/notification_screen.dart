import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/notification_settings.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../services/notification_service.dart';
import '../common/app_theme.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<PendingNotificationRequest> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final list = await NotificationService.instance.getPendingNotifications();
    if (mounted) setState(() { _pending = list; _loading = false; });
  }

  Future<void> _rescheduleAll() async {
    setState(() => _loading = true);
    final events = ref.read(allEventsProvider).valueOrNull ?? [];
    await NotificationService.instance.rescheduleAll(events);
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 재설정되었습니다'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSettingsSheet(NotificationSettings current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSettingsSheet(
        current: current,
        onSave: (settings) async {
          await ref.read(notificationSettingsProvider.notifier).save(settings);
          final events = ref.read(allEventsProvider).valueOrNull ?? [];
          await NotificationService.instance
              .rescheduleAll(events, days: settings.notificationDays);
          await _loadPending();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('알림 설정이 저장되었습니다'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = (ref.watch(allEventsProvider).valueOrNull ?? [])
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final settings = ref.watch(notificationSettingsProvider).valueOrNull ??
        NotificationSettings.defaults();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('알림'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _rescheduleAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('재설정'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── 예약된 알림 수 요약 ──
                SliverToBoxAdapter(
                  child: _SummaryBanner(
                    pendingCount: _pending.length,
                    settings: settings,
                  ),
                ),

                // ── 알림 시기 설정 카드 ──
                SliverToBoxAdapter(
                  child: _SettingsCard(
                    settings: settings,
                    onTap: () => _showSettingsSheet(settings),
                  ),
                ),

                // ── 다가오는 경조사 알림 일정 ──
                if (upcomingEvents.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        '예정된 경조사',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _EventNotifCard(
                          event: upcomingEvents[i],
                          settings: settings,
                        ),
                        childCount: upcomingEvents.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── 상단 요약 배너 ─────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final int pendingCount;
  final NotificationSettings settings;
  const _SummaryBanner({required this.pendingCount, required this.settings});

  String _daysLabel() {
    final days = [...settings.notificationDays]..sort((a, b) => b.compareTo(a));
    return days.map((d) => d == 0 ? 'D-day' : 'D-$d').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '예약된 알림 ${pendingCount}개',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount > 0
                      ? '${_daysLabel()} 알림이 예약되어 있어요'
                      : '예약된 알림이 없어요. 재설정해 보세요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 알림 시기 설정 카드 ────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final NotificationSettings settings;
  final VoidCallback onTap;
  const _SettingsCard({required this.settings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = [...settings.notificationDays]..sort((a, b) => b.compareTo(a));
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '알림 시기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 14, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        '설정 변경',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: days.map((d) {
              final label = d == 0 ? 'D-day' : 'D-$d';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 이벤트별 알림 카드 ─────────────────────────────────────────
class _EventNotifCard extends StatelessWidget {
  final EventModel event;
  final NotificationSettings settings;
  const _EventNotifCard({required this.event, required this.settings});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = event.date.difference(now).inDays;
    final fmt = DateFormat('yyyy년 M월 d일', 'ko_KR');

    final notifDays = <int>[];
    for (final d in settings.notificationDays) {
      final DateTime checkDate = d == 0
          ? DateTime(event.date.year, event.date.month, event.date.day, 9, 0)
          : event.date.subtract(Duration(days: d));
      if (checkDate.isAfter(now)) notifDays.add(d);
    }
    notifDays.sort((a, b) => b.compareTo(a));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이모지 + D-day 배지
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(event.ceremonyType.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        daysLeft <= 7 ? AppTheme.expense : AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'D-$daysLeft',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // 이름 + 날짜
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.personName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.ceremonyType.label} · ${fmt.format(event.date)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                // 예약된 알림 칩
                if (notifDays.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: notifDays.map((d) {
                      final label = d == 0 ? 'D-day' : 'D-$d';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_rounded,
                                size: 10, color: AppTheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    '예약 가능한 알림 없음',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 빈 상태 ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text(
            '예정된 경조사가 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '경조사를 등록하면 자동으로 알림이 설정돼요',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

// ── 알림 설정 바텀시트 ─────────────────────────────────────────
class _NotificationSettingsSheet extends StatefulWidget {
  final NotificationSettings current;
  final Future<void> Function(NotificationSettings) onSave;

  const _NotificationSettingsSheet({
    required this.current,
    required this.onSave,
  });

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late Set<int> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.current.notificationDays);
  }

  void _toggle(int day) {
    setState(() {
      if (_selected.contains(day)) {
        if (_selected.length > 1) _selected.remove(day); // 최소 1개 유지
      } else {
        _selected.add(day);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final newSettings =
        NotificationSettings(notificationDays: _selected.toList());
    await widget.onSave(newSettings);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final availableDays = [...NotificationSettings.availableDays]
      ..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 제목 + 기본값 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '알림 시기 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selected = Set.from(NotificationSettings.defaultDays);
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('기본값으로 초기화',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '알림을 받을 시기를 선택하세요 (최소 1개)',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // 날짜 선택 칩
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableDays.map((day) {
              final isSelected = _selected.contains(day);
              final label = day == 0 ? 'D-day' : 'D-$day';
              final sublabel = day == 0
                  ? '당일'
                  : day == 1
                      ? '1일 전'
                      : '$day일 전';
              return GestureDetector(
                onTap: () => _toggle(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      '저장하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
