import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_provider.dart';
import '../common/app_theme.dart';

class BudgetSettingScreen extends ConsumerStatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  ConsumerState<BudgetSettingScreen> createState() =>
      _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends ConsumerState<BudgetSettingScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final current = ref.read(monthlyBudgetProvider);
    if (current > 0) _ctrl.text = current.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(monthlyBudgetProvider);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('월별 예산 설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '월별 경조사비 예산을 설정하면\n지출이 예산을 초과할 때 경고를 표시합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // 현재 예산 표시
              if (budget > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('현재 예산',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary)),
                      Text(
                        '${fmt.format(budget)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 예산 입력
              Text(
                '새 예산 금액',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  suffixText: '원',
                  suffixStyle: TextStyle(
                      fontSize: 16, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // 빈 값 = 예산 삭제
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return '올바른 금액을 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '비워두면 예산이 삭제됩니다.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),

              // 빠른 금액 선택 칩
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [100000, 200000, 300000, 500000, 1000000]
                    .map((v) => GestureDetector(
                          onTap: () =>
                              setState(() => _ctrl.text = v.toString()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFF1F5F9)),
                            ),
                            child: Text(
                              '${fmt.format(v)}원',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const Spacer(),

              // 저장 버튼
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('저장하기'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (budget > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _clearBudget,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppTheme.expense.withValues(alpha: 0.8),
                    ),
                    child: const Text('예산 삭제'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final val = int.tryParse(_ctrl.text.trim()) ?? 0;
    ref.read(monthlyBudgetProvider.notifier).setBudget(val);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(val > 0 ? '예산이 저장됐습니다.' : '예산이 삭제됐습니다.'),
      backgroundColor:
          val > 0 ? AppTheme.income : AppTheme.textSecondary,
    ));
    Navigator.pop(context);
  }

  void _clearBudget() {
    ref.read(monthlyBudgetProvider.notifier).setBudget(0);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('예산이 삭제됐습니다.'),
    ));
    Navigator.pop(context);
  }
}
