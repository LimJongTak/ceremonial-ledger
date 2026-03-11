import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/calendar_screen.dart';
import '../ledger/ledger_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import '../common/app_theme.dart';
import '../calendar/event_bottom_sheet.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerWidget {
  const MainNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(bottomNavIndexProvider);
    final selectedDate = DateTime.now();

    final screens = [
      const HomeScreen(),
      const CalendarScreen(),
      const LedgerScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: IndexedStack(index: idx, children: screens),
        floatingActionButton: _FAB(selectedDate: selectedDate),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomNav(
          currentIndex: idx,
          onTap: (i) => ref.read(bottomNavIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}

class _FAB extends StatelessWidget {
  final DateTime selectedDate;
  const _FAB({required this.selectedDate});

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4)),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => EventBottomSheet(initialDate: selectedDate),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: '홈'),
      _NavItem(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: '캘린더'),
      _NavItem(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: '장부'),
      _NavItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          label: '통계'),
      _NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: '프로필'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              // 중앙 FAB 자리 비우기
              if (i == 2) return const SizedBox(width: 70);
              final item = i > 2 ? items[i] : items[i];
              final isActive =
                  currentIndex == i || (i > 2 && currentIndex == i);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i < 2
                      ? i
                      : i == 3
                          ? 3
                          : 4),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentIndex ==
                                (i < 2
                                    ? i
                                    : i == 3
                                        ? 3
                                        : 4)
                            ? item.activeIcon
                            : item.icon,
                        size: 22,
                        color: currentIndex ==
                                (i < 2
                                    ? i
                                    : i == 3
                                        ? 3
                                        : 4)
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: currentIndex ==
                                    (i < 2
                                        ? i
                                        : i == 3
                                            ? 3
                                            : 4)
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: currentIndex ==
                                    (i < 2
                                        ? i
                                        : i == 3
                                            ? 3
                                            : 4)
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
