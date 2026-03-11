import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMonthlyBudget = 'monthly_budget';

/// 월별 예산 (0 = 미설정)
class BudgetNotifier extends StateNotifier<int> {
  BudgetNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_kMonthlyBudget) ?? 0;
  }

  Future<void> setBudget(int amount) async {
    state = amount;
    final prefs = await SharedPreferences.getInstance();
    if (amount == 0) {
      await prefs.remove(_kMonthlyBudget);
    } else {
      await prefs.setInt(_kMonthlyBudget, amount);
    }
  }
}

final monthlyBudgetProvider =
    StateNotifierProvider<BudgetNotifier, int>(
  (ref) => BudgetNotifier(),
);
