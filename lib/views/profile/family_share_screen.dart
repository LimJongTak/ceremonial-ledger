import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/family_model.dart';
import '../../models/event_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/family_service.dart';
import '../common/app_theme.dart';

class FamilyShareScreen extends ConsumerStatefulWidget {
  const FamilyShareScreen({super.key});

  @override
  ConsumerState<FamilyShareScreen> createState() => _FamilyShareScreenState();
}

class _FamilyShareScreenState extends ConsumerState<FamilyShareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nameCtrl = TextEditingController(text: '우리 가족 장부');
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _displayName {
    // 앱 프로필 닉네임 우선
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.nickname.isNotEmpty) return profile.nickname;
    // 소셜 로그인 displayName 차선
    final user = ref.read(authStateProvider).value;
    return user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? '멤버';
  }

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyProvider);
    final uid = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '가족 공유 장부',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      body: familyAsync.when(
        data: (family) {
          if (family != null && uid != null) {
            return _FamilyView(
              family: family,
              uid: uid,
              loading: _loading,
              onLeave: () => _handleLeave(uid, family),
            );
          }
          return _NoFamilyView(
            tabCtrl: _tabCtrl,
            nameCtrl: _nameCtrl,
            codeCtrl: _codeCtrl,
            loading: _loading,
            onCreateFamily: uid != null ? () => _createFamily(uid) : null,
            onJoinFamily: uid != null ? () => _joinFamily(uid) : null,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }

  Future<void> _createFamily(String uid) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('가족 이름을 입력해주세요');
      return;
    }
    setState(() => _loading = true);
    try {
      await FamilyService.instance.createFamily(uid, name, _displayName);
      if (mounted) _showSnack('가족 그룹이 생성됐습니다 🎉', success: true);
    } catch (e) {
      if (mounted) _showSnack('오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily(String uid) async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      _showSnack('6자리 코드를 입력해주세요');
      return;
    }
    setState(() => _loading = true);
    try {
      await FamilyService.instance.joinByCode(uid, code, _displayName);
      if (mounted) _showSnack('가족 그룹에 참여했습니다 🎉', success: true);
    } catch (e) {
      if (mounted) _showSnack('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLeave(String uid, FamilyModel family) async {
    final isOwner = family.ownerId == uid;
    final title = isOwner ? '가족 그룹 해산' : '가족 그룹 나가기';
    final content = isOwner
        ? '그룹을 해산하면 모든 공유 내역이 삭제됩니다.\n정말 해산하시겠습니까?'
        : '그룹을 나가면 공유 장부에 더 이상 접근할 수 없습니다.';
    final btnLabel = isOwner ? '해산' : '나가기';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expense,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(btnLabel),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _loading = true);
    try {
      if (isOwner) {
        await FamilyService.instance.deleteFamily(family.id);
        if (mounted) _showSnack('그룹이 해산됐습니다', success: true);
      } else {
        await FamilyService.instance.leaveFamily(uid, family.id);
        if (mounted) _showSnack('그룹에서 나왔습니다', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.income : AppTheme.expense,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── 가족 없을 때: 생성 or 참여 ───────────────────────────────
class _NoFamilyView extends StatelessWidget {
  final TabController tabCtrl;
  final TextEditingController nameCtrl, codeCtrl;
  final bool loading;
  final VoidCallback? onCreateFamily, onJoinFamily;

  const _NoFamilyView({
    required this.tabCtrl,
    required this.nameCtrl,
    required this.codeCtrl,
    required this.loading,
    required this.onCreateFamily,
    required this.onJoinFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 안내 배너
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_outlined,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '가족 공유 장부란?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '부부·가족이 함께 경조사 내역을\n실시간으로 공유하고 관리하세요.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 탭
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: tabCtrl,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '가족 만들기'),
                Tab(text: '코드로 참여'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        Expanded(
          child: TabBarView(
            controller: tabCtrl,
            children: [
              // ── 가족 만들기 탭 ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '가족 이름',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: '예) 우리 가족 장부',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoItem(
                        icon: Icons.vpn_key_outlined,
                        text: '생성 후 6자리 초대 코드가 발급됩니다'),
                    const SizedBox(height: 8),
                    _InfoItem(
                        icon: Icons.share_outlined,
                        text: '코드를 가족에게 공유해 초대하세요'),
                    const SizedBox(height: 8),
                    _InfoItem(
                        icon: Icons.sync_outlined,
                        text: '경조사 내역이 가족 모두에게 실시간 공유됩니다'),
                    const SizedBox(height: 8),
                    _InfoItem(
                        icon: Icons.group_outlined,
                        text: '최대 10명까지 함께 사용할 수 있습니다'),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: loading ? null : onCreateFamily,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.group_add_rounded, size: 18),
                        label: Text(loading ? '처리 중...' : '가족 만들기'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── 코드로 참여 탭 ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '초대 코드 입력',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeCtrl,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 10,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        _UpperCaseFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'XXXXXX',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary
                              .withValues(alpha: 0.3),
                          letterSpacing: 10,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoItem(
                        icon: Icons.person_add_outlined,
                        text: '가족 구성원에게 초대 코드를 받으세요'),
                    const SizedBox(height: 8),
                    _InfoItem(
                        icon: Icons.sync_outlined,
                        text: '참여 즉시 공유 장부에 실시간 접근 가능합니다'),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: loading ? null : onJoinFamily,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.login_rounded, size: 18),
                        label: Text(loading ? '처리 중...' : '참여하기'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 가족 있을 때: 그룹 정보 + 공유 장부 ─────────────────────
class _FamilyView extends ConsumerStatefulWidget {
  final FamilyModel family;
  final String uid;
  final bool loading;
  final VoidCallback? onLeave;

  const _FamilyView({
    required this.family,
    required this.uid,
    required this.loading,
    required this.onLeave,
  });

  @override
  ConsumerState<_FamilyView> createState() => _FamilyViewState();
}

class _FamilyViewState extends ConsumerState<_FamilyView> {
  @override
  void initState() {
    super.initState();
    // 프레임 이후 memberName 동기화 (자신 + 이름 없는 다른 멤버)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMemberName();
      _syncAllMemberNames();
    });
  }

  /// 가족 문서의 memberNames[uid]를 현재 프로필 닉네임과 맞춤.
  /// 이미 정확한 이름이면 불필요한 쓰기를 하지 않음.
  void _syncMemberName() {
    if (!mounted) return;
    final uid = widget.uid;
    final family = widget.family;

    final profile = ref.read(userProfileProvider).value;
    String latestName;
    if (profile != null && profile.nickname.isNotEmpty) {
      latestName = profile.nickname;
    } else {
      final user = ref.read(authStateProvider).value;
      latestName = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : user?.email?.split('@').first ?? '';
    }

    final stored = family.memberNames[uid] ?? '';
    if (latestName.isNotEmpty && stored != latestName) {
      FamilyService.instance.updateMemberName(family.id, uid, latestName);
    }
  }

  /// 이름이 없는 다른 멤버들의 프로필을 Firestore에서 읽어 family 문서에 갱신
  Future<void> _syncAllMemberNames() async {
    if (!mounted) return;
    final family = widget.family;
    final uid = widget.uid;
    final missing = family.memberIds
        .where((id) => id != uid && (family.memberNames[id] ?? '').isEmpty)
        .toList();
    if (missing.isEmpty) return;
    await FamilyService.instance.syncMemberNames(family.id, missing);
  }

  // 별칭 수정 바텀시트
  void _showAliasEditor(String memberId, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AliasEditorSheet(
        family: widget.family,
        memberId: memberId,
        currentName: currentName,
      ),
    );
  }

  // 이벤트 상세 바텀시트
  void _showEventDetail(EventModel event, String memberName, bool isMe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(
        event: event,
        memberName: memberName,
        isMe: isMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    final uid = widget.uid;
    final isOwner = family.ownerId == uid;
    final eventsAsync = ref.watch(allEventsProvider);
    final events = eventsAsync.valueOrNull ?? [];

    // 이달 요약
    final now = DateTime.now();
    final monthEvents = events
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final totalIncome =
        monthEvents.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
    final totalExpense =
        monthEvents.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
    final recentEvents = events.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── 그룹 정보 카드 ───────────────────────────────────
        _Card(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      '멤버 ${family.memberIds.length}명 함께 공유 중',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '방장',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 이달 공유 장부 요약 카드 (NEW) ───────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '이달의 공유 장부',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3),
                  ),
                  const Spacer(),
                  Text(
                    '${now.month}월',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: '수입',
                      amount: totalIncome,
                      color: AppTheme.income,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: '지출',
                      amount: totalExpense,
                      color: AppTheme.expense,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: '잔액',
                      amount: totalIncome - totalExpense,
                      color: AppTheme.primary,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              if (monthEvents.isEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '이달 등록된 공유 내역이 없습니다',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 최근 공유 내역 카드 (NEW) ─────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최근 공유 내역',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 12),
              if (recentEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 36,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          '아직 공유된 내역이 없습니다\n새 일정을 등록하면 여기에 표시됩니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentEvents.asMap().entries.map((entry) {
                  final e = entry.value;
                  final isLast = entry.key == recentEvents.length - 1;
                  final memberName = family.displayNameFor(e.userId);
                  return Column(
                    children: [
                      _EventRow(
                        event: e,
                        memberName: memberName,
                        isMe: e.userId == uid,
                        onTap: () => _showEventDetail(
                            e, memberName, e.userId == uid),
                      ),
                      if (!isLast)
                        Divider(
                            height: 16,
                            color: Colors.black.withValues(alpha: 0.05)),
                    ],
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 멤버 목록 카드 ───────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '멤버',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3),
                  ),
                  Text(
                    '${family.memberIds.length} / 10',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '이름 옆 ✏️를 눌러 별칭을 설정할 수 있습니다',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              ...family.memberIds.asMap().entries.map((entry) {
                final memberId = entry.value;
                final isMe = memberId == uid;
                final isMemberOwner = memberId == family.ownerId;
                final baseName = family.memberNames[memberId] ?? '멤버';
                final alias = family.memberAliases[memberId] ?? '';
                final displayName = alias.isNotEmpty ? alias : baseName;
                final hasAlias = alias.isNotEmpty;
                final isLast = entry.key == family.memberIds.length - 1;

                // 아바타 이니셜
                final initial =
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _showAliasEditor(memberId, baseName),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // 아바타
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isMe
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isMe
                                            ? '$displayName (나)'
                                            : displayName,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary),
                                      ),
                                      if (hasAlias) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          baseName,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary
                                                  .withValues(alpha: 0.6)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isMemberOwner)
                                    Text(
                                      '방장',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.8)),
                                    ),
                                ],
                              ),
                            ),
                            // 별칭 편집 버튼
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          height: 16,
                          color: Colors.black.withValues(alpha: 0.05)),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 초대 코드 카드 ───────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '초대 코드',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        family.inviteCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: family.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('코드가 복사됐습니다'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          size: 20, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '이 코드를 공유하면 가족이 참여할 수 있습니다.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── 나가기 / 해산 버튼 ───────────────────────────────
        OutlinedButton.icon(
          onPressed: widget.loading ? null : widget.onLeave,
          icon: Icon(
            isOwner
                ? Icons.delete_outline_rounded
                : Icons.exit_to_app_rounded,
            size: 18,
          ),
          label: Text(isOwner ? '그룹 해산' : '그룹 나가기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.expense,
            side: BorderSide(
                color: AppTheme.expense.withValues(alpha: 0.4)),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          isOwner
              ? '그룹을 해산하면 모든 공유 내역이 삭제됩니다.'
              : '그룹을 나가면 공유 장부에 더 이상 접근할 수 없습니다.',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}

// ── 요약 타일 ────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  String _fmt(int v) => v
      .abs()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${_fmt(amount)}원',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

// ── 이벤트 행 ─────────────────────────────────────────────────
class _EventRow extends StatelessWidget {
  final EventModel event;
  final String memberName;
  final bool isMe;
  final VoidCallback? onTap;

  const _EventRow({
    required this.event,
    required this.memberName,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        event.isIncome ? AppTheme.income : AppTheme.expense;
    final initial =
        memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          // 멤버 아바타
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isMe
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isMe ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? '$memberName (나)' : memberName,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.ceremonyType.emoji,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  event.personName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            event.formattedAmount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 카드 위젯 ────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      );
}

// ── 안내 텍스트 아이템 ────────────────────────────────────────
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      );
}

// ── 별칭 편집 바텀시트 ─────────────────────────────────────────
class _AliasEditorSheet extends StatefulWidget {
  final FamilyModel family;
  final String memberId;
  final String currentName;

  const _AliasEditorSheet({
    required this.family,
    required this.memberId,
    required this.currentName,
  });

  @override
  State<_AliasEditorSheet> createState() => _AliasEditorSheetState();
}

class _AliasEditorSheetState extends State<_AliasEditorSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.family.memberAliases[widget.memberId] ?? '');
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAlias =
        widget.family.memberAliases[widget.memberId]?.isNotEmpty == true;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '\'${widget.currentName}\'의 별칭 설정',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              '내가 알아보기 쉽게 이름을 붙여두세요.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: '예) 남편, 아내, 엄마',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: _ctrl.clear,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasAlias) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await FamilyService.instance.updateMemberAlias(
                            widget.family.id, widget.memberId, '');
                        if (mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.12)),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('별칭 삭제'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      final alias = _ctrl.text.trim();
                      await FamilyService.instance.updateMemberAlias(
                          widget.family.id, widget.memberId, alias);
                      if (mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이벤트 상세 바텀시트 ──────────────────────────────────────
class _EventDetailSheet extends StatelessWidget {
  final EventModel event;
  final String memberName;
  final bool isMe;

  const _EventDetailSheet({
    required this.event,
    required this.memberName,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.isIncome ? AppTheme.income : AppTheme.expense;
    final dateStr =
        '${event.date.year}.${event.date.month.toString().padLeft(2, '0')}.${event.date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 상단: 이모지 + 이름 + 금액
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(event.ceremonyType.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.personName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${event.ceremonyType.label} · ${event.relation.label}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                event.formattedAmount,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          // 상세 정보 행들
          _DetailRow(label: '날짜', value: dateStr),
          _DetailRow(label: '유형', value: event.eventType.label),
          _DetailRow(
              label: '등록자',
              value: isMe ? '$memberName (나)' : memberName),
          if (event.memo != null && event.memo!.isNotEmpty)
            _DetailRow(label: '메모', value: event.memo!),
        ],
      ),
    );
  }
}

// ── 상세 정보 행 ──────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      );
}

// ── 대문자 입력 포매터 ────────────────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}
