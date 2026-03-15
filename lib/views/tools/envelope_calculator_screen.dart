import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../common/app_theme.dart';

// 관계 × 경조사별 추천 금액 가이드 [최소, 최대] (단위: 만원)
const _guide = {
  CeremonyType.wedding: {
    RelationType.family: [10, 30],
    RelationType.relative: [5, 15],
    RelationType.friend: [5, 10],
    RelationType.colleague: [5, 10],
    RelationType.neighbor: [3, 5],
    RelationType.other: [3, 5],
  },
  CeremonyType.funeral: {
    RelationType.family: [10, 30],
    RelationType.relative: [5, 10],
    RelationType.friend: [5, 10],
    RelationType.colleague: [3, 5],
    RelationType.neighbor: [3, 5],
    RelationType.other: [3, 5],
  },
  CeremonyType.babyShower: {
    RelationType.family: [5, 10],
    RelationType.relative: [3, 5],
    RelationType.friend: [3, 5],
    RelationType.colleague: [2, 3],
    RelationType.neighbor: [2, 3],
    RelationType.other: [2, 3],
  },
  CeremonyType.birthday: {
    RelationType.family: [5, 10],
    RelationType.relative: [3, 5],
    RelationType.friend: [2, 5],
    RelationType.colleague: [1, 3],
    RelationType.neighbor: [1, 2],
    RelationType.other: [1, 2],
  },
  CeremonyType.graduation: {
    RelationType.family: [5, 10],
    RelationType.relative: [3, 5],
    RelationType.friend: [3, 5],
    RelationType.colleague: [2, 3],
    RelationType.neighbor: [2, 3],
    RelationType.other: [2, 3],
  },
  CeremonyType.houseWarming: {
    RelationType.family: [5, 10],
    RelationType.relative: [3, 5],
    RelationType.friend: [3, 5],
    RelationType.colleague: [2, 3],
    RelationType.neighbor: [2, 3],
    RelationType.other: [2, 3],
  },
  CeremonyType.promotion: {
    RelationType.family: [5, 10],
    RelationType.relative: [3, 5],
    RelationType.friend: [3, 5],
    RelationType.colleague: [3, 5],
    RelationType.neighbor: [2, 3],
    RelationType.other: [2, 3],
  },
  CeremonyType.other: {
    RelationType.family: [3, 5],
    RelationType.relative: [2, 3],
    RelationType.friend: [2, 3],
    RelationType.colleague: [2, 3],
    RelationType.neighbor: [1, 2],
    RelationType.other: [1, 2],
  },
};

// 식사 제공 시 추가 금액 (만원)
const _mealExtra = {
  RelationType.family: 0,
  RelationType.relative: 3,
  RelationType.friend: 3,
  RelationType.colleague: 3,
  RelationType.neighbor: 2,
  RelationType.other: 2,
};

const _tips = {
  CeremonyType.wedding: '결혼식은 식사 여부, 단체 참석 여부에 따라 금액이 달라져요. 부부 동반 참석 시 두 배를 기준으로 하세요.',
  CeremonyType.funeral: '부의금은 짝수보다 홀수(3, 5, 7만원 단위)가 관습적입니다. 가까울수록 더 넉넉히 준비하세요.',
  CeremonyType.babyShower: '현금보다 실용적인 선물(기저귀, 용품)을 선호하는 경우도 많아요.',
  CeremonyType.birthday: '나이대가 올라갈수록 현금 선호도가 높아집니다.',
  CeremonyType.graduation: '입학/졸업 모두 해당돼요. 진학 여부에 따라 금액을 조정해보세요.',
  CeremonyType.houseWarming: '현금 외에도 생활용품이나 식재료 세트가 좋은 선물이 됩니다.',
  CeremonyType.promotion: '승진 축하는 직장 관계에서 주로 이루어지며 회식 참여로 대체되기도 해요.',
  CeremonyType.other: '상황과 친밀도에 따라 유연하게 조정하세요.',
};

class EnvelopeCalculatorScreen extends StatefulWidget {
  const EnvelopeCalculatorScreen({super.key});

  @override
  State<EnvelopeCalculatorScreen> createState() =>
      _EnvelopeCalculatorScreenState();
}

class _EnvelopeCalculatorScreenState extends State<EnvelopeCalculatorScreen> {
  CeremonyType _ceremony = CeremonyType.wedding;
  RelationType _relation = RelationType.friend;
  bool _withMeal = false;
  bool _couple = false; // 커플/부부 참석

  List<int> get _range {
    final base = _guide[_ceremony]![_relation]!;
    int min = base[0];
    int max = base[1];
    if (_withMeal) {
      final extra = _mealExtra[_relation]!;
      min += extra;
      max += extra;
    }
    if (_couple) {
      min *= 2;
      max *= 2;
    }
    return [min, max];
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final tip = _tips[_ceremony] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('봉투 계산기',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9a30ae), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Text('💌', style: TextStyle(fontSize: 28)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('경조사 봉투 금액 가이드',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      SizedBox(height: 4),
                      Text('관계와 상황에 맞는 적정 금액을 추천해드려요',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // 경조사 선택
            _SectionLabel(label: '경조사 종류'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CeremonyType.values.map((c) {
                final selected = _ceremony == c;
                return GestureDetector(
                  onTap: () => setState(() => _ceremony = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey[200]!),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]
                          : [],
                    ),
                    child: Text(
                      '${c.emoji} ${c.label}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.textPrimary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 관계 선택
            _SectionLabel(label: '관 계'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RelationType.values.map((r) {
                final selected = _relation == r;
                return GestureDetector(
                  onTap: () => setState(() => _relation = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.secondary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? AppTheme.secondary
                              : Colors.grey[200]!),
                    ),
                    child: Text(
                      r.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.textPrimary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 옵션
            _SectionLabel(label: '추가 옵션'),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.restaurant_outlined,
              title: '식사 제공 있음',
              subtitle: '뷔페·식사가 포함된 행사',
              value: _withMeal,
              onChanged: (v) => setState(() => _withMeal = v),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.people_outline_rounded,
              title: '부부/커플 동반 참석',
              subtitle: '2인 기준으로 계산',
              value: _couple,
              onChanged: (v) => setState(() => _couple = v),
            ),
            const SizedBox(height: 28),

            // 결과 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('추천 금액',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Text(
                    '${range[0]}만원 ~ ${range[1]}만원',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ceremony.emoji} ${_ceremony.label} · ${_relation.label}${_withMeal ? ' · 식사포함' : ''}${_couple ? ' · 2인' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Divider(height: 28),
                  // 금액 버튼들 (빠른 선택)
                  Text('자주 내는 금액',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _suggestAmounts(range)
                        .map((a) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${a}만원',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 팁 카드
            if (tip.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF92400E),
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<int> _suggestAmounts(List<int> range) {
    final min = range[0];
    final max = range[1];
    final List<int> amounts = [];
    // 범위 내 대표 금액 제안 (5만원 단위)
    for (int a = min; a <= max; a += (max - min <= 5 ? 1 : 5)) {
      amounts.add(a);
      if (amounts.length >= 4) break;
    }
    if (!amounts.contains(min)) amounts.insert(0, min);
    if (!amounts.contains(max)) amounts.add(max);
    return amounts.toSet().toList()..sort();
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: value ? AppTheme.primary : Colors.grey[200]!,
                width: value ? 1.5 : 1),
          ),
          child: Row(children: [
            Icon(icon,
                size: 20,
                color: value ? AppTheme.primary : Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
          ]),
        ),
      );
}
