import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../calendar/event_bottom_sheet.dart';
import '../common/app_theme.dart';
import '../search/search_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allEventsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (events) => _HomeBody(events: events, user: user),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final List<EventModel> events;
  final dynamic user;
  const _HomeBody({required this.events, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 프로필 닉네임 우선, 없으면 Firebase displayName, 없으면 이메일 앞부분
    final nickname = ref.watch(userProfileProvider).valueOrNull?.nickname
        ?? user?.displayName
        ?? user?.email?.split('@').first
        ?? '사용자';

    final now = DateTime.now();
    final thisMonth = events
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final totalIncome =
        thisMonth.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        thisMonth.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final balance = totalIncome - totalExpense;

    // 이번달 다가오는 이벤트 (앞으로 30일)
    final upcoming = events
        .where((e) =>
            e.date.isAfter(now) &&
            e.date.isBefore(now.add(const Duration(days: 30))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 최근 내역
    final recent = [...events]..sort((a, b) => b.date.compareTo(a.date));
    final recentTop = recent.take(5).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 상단 헤더 ──
        SliverToBoxAdapter(child: _Header(nickname: nickname, balance: balance)),

        // ── 이번달 요약 카드 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _MonthSummaryCards(
              income: totalIncome,
              expense: totalExpense,
              count: thisMonth.length,
            ),
          ),
        ),

        // ── 다가오는 경조사 ──
        if (upcoming.isNotEmpty) ...[
          const SliverToBoxAdapter(
              child: _SectionTitle(
                  title: '다가오는 경조사', icon: Icons.upcoming_outlined)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: upcoming.length,
                itemBuilder: (_, i) => _UpcomingCard(event: upcoming[i]),
              ),
            ),
          ),
        ],

        // ── 최근 내역 ──
        const SliverToBoxAdapter(
            child: _SectionTitle(title: '최근 내역', icon: Icons.history_outlined)),
        if (recentTop.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RecentItem(event: recentTop[i]),
                childCount: recentTop.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String nickname;
  final int balance;
  const _Header({required this.nickname, required this.balance});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fmt = NumberFormat('#,###');
    final greeting = now.hour < 12
        ? '좋은 아침이에요'
        : now.hour < 18
            ? '안녕하세요'
            : '좋은 저녁이에요';

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 20, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('$nickname 님',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ],
              ),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SearchScreen()),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppTheme.textPrimary, size: 20),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 24),

          // 잔액 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번 달 잔액',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${fmt.format(balance.abs())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 4),
                      child: Text('원',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (balance < 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.expense.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('지출 초과',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(DateFormat('yyyy년 M월', 'ko_KR').format(DateTime.now()),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 이번달 요약 카드들 ────────────────────────────────────────
class _MonthSummaryCards extends StatelessWidget {
  final int income, expense, count;
  const _MonthSummaryCards(
      {required this.income, required this.expense, required this.count});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        Expanded(
            child: _SummaryMini(
          label: '수입',
          value: '${fmt.format(income)}원',
          color: AppTheme.income,
          icon: Icons.arrow_downward_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryMini(
          label: '지출',
          value: '${fmt.format(expense)}원',
          color: AppTheme.expense,
          icon: Icons.arrow_upward_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryMini(
          label: '건수',
          value: '$count건',
          color: AppTheme.secondary,
          icon: Icons.receipt_long_outlined,
        )),
      ]),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryMini(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

// ── 다가오는 경조사 카드 ──────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final EventModel event;
  const _UpcomingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final daysLeft = event.date.difference(DateTime.now()).inDays;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(event.ceremonyType.emoji,
                style: const TextStyle(fontSize: 22)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: daysLeft <= 7
                    ? AppTheme.expense.withValues(alpha: 0.1)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('D-$daysLeft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: daysLeft <= 7 ? AppTheme.expense : AppTheme.primary,
                  )),
            ),
          ]),
          const SizedBox(height: 8),
          Text(event.personName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(event.ceremonyType.label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── 섹션 타이틀 ───────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3)),
        ]),
      );
}

// ── 최근 내역 아이템 ──────────────────────────────────────────
class _RecentItem extends ConsumerWidget {
  final EventModel event;
  const _RecentItem({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inc = event.isIncome;
    final fmt = NumberFormat('#,###');
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            EventBottomSheet(initialDate: event.date, eventToEdit: event),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(event.ceremonyType.emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.personName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text('${event.ceremonyType.label} · ${event.relation.label}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${inc ? '+' : '-'}${fmt.format(event.amount)}원',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: inc ? AppTheme.income : AppTheme.expense,
                ),
              ),
              const SizedBox(height: 3),
              Text(DateFormat('M/d').format(event.date),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(children: [
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('아직 내역이 없어요',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          SizedBox(height: 4),
          Text('하단 + 버튼으로 첫 내역을 추가해보세요',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
        ]),
      );
}
