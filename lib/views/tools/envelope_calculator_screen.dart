import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../common/app_theme.dart';

// ─────────────────────────────────────────────
// 세분화된 관계 유형 (계산기 전용)
// ─────────────────────────────────────────────
enum _RelDetail {
  familyParent,    // 부모님
  familySibling,   // 형제자매
  familyChild,     // 자녀
  relativeClose,   // 가까운 친척
  relativeDistant, // 먼 친척
  friendClose,     // 친한 친구
  friendNormal,    // 보통 친구
  friendAcquaint,  // 지인
  workBoss,        // 상사
  workPeer,        // 동료
  workJunior,      // 부하직원
  neighborClose,   // 가까운 이웃
  neighborNormal,  // 이웃
  other,           // 기타
}

extension _RelDetailExt on _RelDetail {
  String get label => const {
    _RelDetail.familyParent:    '부모님',
    _RelDetail.familySibling:   '형제자매',
    _RelDetail.familyChild:     '자녀',
    _RelDetail.relativeClose:   '가까운 친척',
    _RelDetail.relativeDistant: '먼 친척',
    _RelDetail.friendClose:     '친한 친구',
    _RelDetail.friendNormal:    '보통 친구',
    _RelDetail.friendAcquaint:  '지인',
    _RelDetail.workBoss:        '상사',
    _RelDetail.workPeer:        '동료',
    _RelDetail.workJunior:      '부하직원',
    _RelDetail.neighborClose:   '가까운 이웃',
    _RelDetail.neighborNormal:  '이웃',
    _RelDetail.other:           '기타',
  }[this]!;
}

// ─────────────────────────────────────────────
// 관계 그룹
// ─────────────────────────────────────────────
const _relGroups = [
  ('가족', [
    _RelDetail.familyParent,
    _RelDetail.familySibling,
    _RelDetail.familyChild,
  ]),
  ('친척', [
    _RelDetail.relativeClose,
    _RelDetail.relativeDistant,
  ]),
  ('친구', [
    _RelDetail.friendClose,
    _RelDetail.friendNormal,
    _RelDetail.friendAcquaint,
  ]),
  ('직장', [
    _RelDetail.workBoss,
    _RelDetail.workPeer,
    _RelDetail.workJunior,
  ]),
  ('이웃·기타', [
    _RelDetail.neighborClose,
    _RelDetail.neighborNormal,
    _RelDetail.other,
  ]),
];

// ─────────────────────────────────────────────
// 관계 × 경조사별 추천 금액 가이드 [최소, 최대] (단위: 만원)
// ─────────────────────────────────────────────
const _guide = <CeremonyType, Map<_RelDetail, List<int>>>{
  CeremonyType.wedding: {
    _RelDetail.familyParent:    [20, 50],
    _RelDetail.familySibling:   [10, 30],
    _RelDetail.familyChild:     [10, 30],
    _RelDetail.relativeClose:   [10, 20],
    _RelDetail.relativeDistant: [5,  10],
    _RelDetail.friendClose:     [10, 20],
    _RelDetail.friendNormal:    [5,  10],
    _RelDetail.friendAcquaint:  [3,   5],
    _RelDetail.workBoss:        [5,  10],
    _RelDetail.workPeer:        [5,  10],
    _RelDetail.workJunior:      [3,   5],
    _RelDetail.neighborClose:   [5,  10],
    _RelDetail.neighborNormal:  [3,   5],
    _RelDetail.other:           [3,   5],
  },
  CeremonyType.funeral: {
    // 홀수 단위 관습 — 3·5·7·10만원
    _RelDetail.familyParent:    [10, 30],
    _RelDetail.familySibling:   [10, 20],
    _RelDetail.familyChild:     [10, 20],
    _RelDetail.relativeClose:   [7,  10],
    _RelDetail.relativeDistant: [5,   7],
    _RelDetail.friendClose:     [7,  10],
    _RelDetail.friendNormal:    [5,   7],
    _RelDetail.friendAcquaint:  [3,   5],
    _RelDetail.workBoss:        [5,   7],
    _RelDetail.workPeer:        [3,   5],
    _RelDetail.workJunior:      [3,   5],
    _RelDetail.neighborClose:   [3,   5],
    _RelDetail.neighborNormal:  [3,   3],
    _RelDetail.other:           [3,   3],
  },
  CeremonyType.babyShower: {
    _RelDetail.familyParent:    [10, 20],
    _RelDetail.familySibling:   [5,  10],
    _RelDetail.familyChild:     [5,  10],
    _RelDetail.relativeClose:   [5,  10],
    _RelDetail.relativeDistant: [3,   5],
    _RelDetail.friendClose:     [5,  10],
    _RelDetail.friendNormal:    [3,   5],
    _RelDetail.friendAcquaint:  [2,   3],
    _RelDetail.workBoss:        [3,   5],
    _RelDetail.workPeer:        [2,   3],
    _RelDetail.workJunior:      [2,   3],
    _RelDetail.neighborClose:   [2,   3],
    _RelDetail.neighborNormal:  [2,   3],
    _RelDetail.other:           [1,   2],
  },
  CeremonyType.birthday: {
    _RelDetail.familyParent:    [5,  10],
    _RelDetail.familySibling:   [3,   5],
    _RelDetail.familyChild:     [5,  10],
    _RelDetail.relativeClose:   [3,   5],
    _RelDetail.relativeDistant: [2,   3],
    _RelDetail.friendClose:     [3,   5],
    _RelDetail.friendNormal:    [2,   3],
    _RelDetail.friendAcquaint:  [1,   2],
    _RelDetail.workBoss:        [2,   3],
    _RelDetail.workPeer:        [1,   3],
    _RelDetail.workJunior:      [1,   2],
    _RelDetail.neighborClose:   [1,   2],
    _RelDetail.neighborNormal:  [1,   2],
    _RelDetail.other:           [1,   1],
  },
  CeremonyType.graduation: {
    _RelDetail.familyParent:    [5,  10],
    _RelDetail.familySibling:   [5,  10],
    _RelDetail.familyChild:     [5,  10],
    _RelDetail.relativeClose:   [5,  10],
    _RelDetail.relativeDistant: [3,   5],
    _RelDetail.friendClose:     [5,  10],
    _RelDetail.friendNormal:    [3,   5],
    _RelDetail.friendAcquaint:  [2,   3],
    _RelDetail.workBoss:        [3,   5],
    _RelDetail.workPeer:        [2,   3],
    _RelDetail.workJunior:      [2,   3],
    _RelDetail.neighborClose:   [2,   3],
    _RelDetail.neighborNormal:  [2,   3],
    _RelDetail.other:           [1,   2],
  },
  CeremonyType.houseWarming: {
    _RelDetail.familyParent:    [5,  10],
    _RelDetail.familySibling:   [5,  10],
    _RelDetail.familyChild:     [5,  10],
    _RelDetail.relativeClose:   [5,  10],
    _RelDetail.relativeDistant: [3,   5],
    _RelDetail.friendClose:     [5,  10],
    _RelDetail.friendNormal:    [3,   5],
    _RelDetail.friendAcquaint:  [2,   3],
    _RelDetail.workBoss:        [3,   5],
    _RelDetail.workPeer:        [2,   3],
    _RelDetail.workJunior:      [2,   3],
    _RelDetail.neighborClose:   [3,   5],
    _RelDetail.neighborNormal:  [2,   3],
    _RelDetail.other:           [2,   3],
  },
  CeremonyType.promotion: {
    _RelDetail.familyParent:    [5,  10],
    _RelDetail.familySibling:   [5,  10],
    _RelDetail.familyChild:     [5,  10],
    _RelDetail.relativeClose:   [3,   5],
    _RelDetail.relativeDistant: [3,   5],
    _RelDetail.friendClose:     [5,  10],
    _RelDetail.friendNormal:    [3,   5],
    _RelDetail.friendAcquaint:  [2,   3],
    _RelDetail.workBoss:        [3,   5],
    _RelDetail.workPeer:        [3,   5],
    _RelDetail.workJunior:      [2,   3],
    _RelDetail.neighborClose:   [2,   3],
    _RelDetail.neighborNormal:  [2,   3],
    _RelDetail.other:           [2,   3],
  },
  CeremonyType.other: {
    _RelDetail.familyParent:    [5,  10],
    _RelDetail.familySibling:   [3,   5],
    _RelDetail.familyChild:     [3,   5],
    _RelDetail.relativeClose:   [3,   5],
    _RelDetail.relativeDistant: [2,   3],
    _RelDetail.friendClose:     [3,   5],
    _RelDetail.friendNormal:    [2,   3],
    _RelDetail.friendAcquaint:  [1,   2],
    _RelDetail.workBoss:        [2,   3],
    _RelDetail.workPeer:        [2,   3],
    _RelDetail.workJunior:      [1,   2],
    _RelDetail.neighborClose:   [1,   2],
    _RelDetail.neighborNormal:  [1,   2],
    _RelDetail.other:           [1,   1],
  },
};

// ─────────────────────────────────────────────
// 식사 제공 시 추가 금액 (만원)
// ─────────────────────────────────────────────
const _mealExtra = <_RelDetail, int>{
  _RelDetail.familyParent:    0,
  _RelDetail.familySibling:   0,
  _RelDetail.familyChild:     0,
  _RelDetail.relativeClose:   3,
  _RelDetail.relativeDistant: 3,
  _RelDetail.friendClose:     3,
  _RelDetail.friendNormal:    3,
  _RelDetail.friendAcquaint:  2,
  _RelDetail.workBoss:        3,
  _RelDetail.workPeer:        3,
  _RelDetail.workJunior:      2,
  _RelDetail.neighborClose:   2,
  _RelDetail.neighborNormal:  2,
  _RelDetail.other:           2,
};

// ─────────────────────────────────────────────
// 경조사별 관습 배지 (null이면 표시 안 함)
// ─────────────────────────────────────────────
const _ceremonyConvention = <CeremonyType, String?>{
  CeremonyType.wedding:      '홀수·5의 배수 단위 선호 (5·10·20만원)',
  CeremonyType.funeral:      '홀수 단위 관습 — 3·5·7·10만원',
  CeremonyType.babyShower:   null,
  CeremonyType.birthday:     null,
  CeremonyType.graduation:   null,
  CeremonyType.houseWarming: null,
  CeremonyType.promotion:    null,
  CeremonyType.other:        null,
};

// 경조사별 자주 내는 금액 후보 (홀수·단위 등 관습 반영)
const _ceremonyCandidates = <CeremonyType, List<int>>{
  CeremonyType.wedding:      [5, 10, 15, 20, 30, 50],
  CeremonyType.funeral:      [3, 5, 7, 10, 20, 30],   // 홀수
  CeremonyType.babyShower:   [3, 5, 10, 20],
  CeremonyType.birthday:     [1, 2, 3, 5, 10],
  CeremonyType.graduation:   [3, 5, 10, 20],
  CeremonyType.houseWarming: [3, 5, 10, 20],
  CeremonyType.promotion:    [3, 5, 10],
  CeremonyType.other:        [1, 2, 3, 5, 10],
};

// ─────────────────────────────────────────────
// 경조사별 팁
// ─────────────────────────────────────────────
const _tips = <CeremonyType, String>{
  CeremonyType.wedding:
      '결혼식은 식사 여부, 단체 참석 여부에 따라 금액이 달라져요. 부부 동반 참석 시 두 배를 기준으로 하세요.',
  CeremonyType.funeral:
      '부의금은 홀수(3·5·7·10만원) 단위가 전통 관습입니다. 가까울수록 더 넉넉히 준비하세요.',
  CeremonyType.babyShower:
      '현금보다 실용적인 선물(기저귀, 육아용품)을 선호하는 경우도 많아요.',
  CeremonyType.birthday:
      '나이대가 올라갈수록 현금 선호도가 높아집니다.',
  CeremonyType.graduation:
      '입학·졸업 모두 해당돼요. 진학 여부에 따라 금액을 조정해보세요.',
  CeremonyType.houseWarming:
      '현금 외에도 생활용품이나 식재료 세트가 좋은 선물이 됩니다.',
  CeremonyType.promotion:
      '승진 축하는 직장 관계에서 주로 이루어지며 회식 참여로 대체되기도 해요.',
  CeremonyType.other:
      '상황과 친밀도에 따라 유연하게 조정하세요.',
};

// ─────────────────────────────────────────────
// 화면
// ─────────────────────────────────────────────
class EnvelopeCalculatorScreen extends StatefulWidget {
  const EnvelopeCalculatorScreen({super.key});

  @override
  State<EnvelopeCalculatorScreen> createState() =>
      _EnvelopeCalculatorScreenState();
}

class _EnvelopeCalculatorScreenState extends State<EnvelopeCalculatorScreen> {
  CeremonyType _ceremony = CeremonyType.wedding;
  _RelDetail _relation = _RelDetail.friendNormal;
  bool _withMeal = false;
  bool _couple = false;

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

  // 관습에 맞는 후보 중 범위 근처 금액만 추림
  List<int> _suggestAmounts(List<int> range) {
    final min = range[0];
    final max = range[1];
    final candidates = _ceremonyCandidates[_ceremony]!;

    // 범위 ±50% 이내 후보 우선
    final inRange = candidates.where((a) => a >= min && a <= max).toList();
    if (inRange.isNotEmpty) return inRange;

    // 없으면 가장 가까운 2개
    final sorted = [...candidates]
      ..sort((a, b) => (a - (min + max) ~/ 2).abs().compareTo((b - (min + max) ~/ 2).abs()));
    return sorted.take(3).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final tip = _tips[_ceremony] ?? '';
    final convention = _ceremonyConvention[_ceremony];

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
            // 헤더 카드
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
            const _SectionLabel(label: '경조사 종류'),
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
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey[200]!),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
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

            // 관습 배지
            if (convention != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(convention,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7B4F00),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 관계 선택 (그룹별)
            const _SectionLabel(label: '관 계'),
            const SizedBox(height: 12),
            ..._relGroups.map((group) {
              final (groupLabel, items) = group;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((r) {
                        final selected = _relation == r;
                        return GestureDetector(
                          onTap: () => setState(() => _relation = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.secondary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: selected
                                      ? AppTheme.secondary
                                      : Colors.grey[200]!,
                                  width: selected ? 1.5 : 1),
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
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // 추가 옵션
            const _SectionLabel(label: '추가 옵션'),
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
                    '${_ceremony.emoji} ${_ceremony.label} · ${_relation.label}'
                    '${_withMeal ? ' · 식사포함' : ''}'
                    '${_couple ? ' · 2인' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 28),
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
                              child: Text('$a만원',
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
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
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
}

// ─────────────────────────────────────────────
// 공용 위젯
// ─────────────────────────────────────────────
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
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primary,
            ),
          ]),
        ),
      );
}
