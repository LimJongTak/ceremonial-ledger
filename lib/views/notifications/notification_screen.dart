import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = (ref.watch(allEventsProvider).valueOrNull ?? [])
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

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
                  child: _SummaryBanner(pendingCount: _pending.length),
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
                        (_, i) => _EventNotifCard(event: upcomingEvents[i]),
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
  const _SummaryBanner({required this.pendingCount});

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
                  '예약된 알림 $pendingCount개',
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
                      ? 'D-7, D-1, D-day 알림이 예약되어 있어요'
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

// ── 이벤트별 알림 카드 ─────────────────────────────────────────
class _EventNotifCard extends StatelessWidget {
  final dynamic event;
  const _EventNotifCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = event.date.difference(now).inDays;
    final fmt = DateFormat('yyyy년 M월 d일', 'ko_KR');

    final notifDays = <int>[];
    if (event.date.subtract(const Duration(days: 7)).isAfter(now)) notifDays.add(7);
    if (event.date.subtract(const Duration(days: 1)).isAfter(now)) notifDays.add(1);
    if (DateTime(event.date.year, event.date.month, event.date.day, 9, 0).isAfter(now)) notifDays.add(0);

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
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: daysLeft <= 7 ? AppTheme.expense : AppTheme.primary,
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
