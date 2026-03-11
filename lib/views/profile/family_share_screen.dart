import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/family_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyProvider);
    final uid = ref.watch(currentUserIdProvider);
    final nicknamesAsync = ref.watch(familyMemberNicknamesProvider);

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
              nicknames: nicknamesAsync.valueOrNull ?? {},
              loading: _loading,
              onLeave: () => _handleLeave(uid, family),
            );
          }
          return _NoFamilyView(
            tabCtrl: _tabCtrl,
            nameCtrl: _nameCtrl,
            codeCtrl: _codeCtrl,
            loading: _loading,
            onCreateFamily:
                uid != null ? () => _createFamily(uid) : null,
            onJoinFamily:
                uid != null ? () => _joinFamily(uid) : null,
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
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
      await FamilyService.instance.createFamily(uid, name);
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
      await FamilyService.instance.joinByCode(uid, code);
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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

// ── 가족 있을 때: 그룹 정보 표시 ────────────────────────────
class _FamilyView extends StatelessWidget {
  final FamilyModel family;
  final String uid;
  final Map<String, String> nicknames;
  final bool loading;
  final VoidCallback? onLeave;

  const _FamilyView({
    required this.family,
    required this.uid,
    required this.nicknames,
    required this.loading,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = family.ownerId == uid;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 그룹 정보 카드
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
                      '멤버 ${family.memberIds.length}명',
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

        // 초대 코드 카드
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '초대 코드',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5),
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

        const SizedBox(height: 14),

        // 멤버 목록 카드
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5),
                  ),
                  Text(
                    '${family.memberIds.length} / 10',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...family.memberIds.asMap().entries.map((entry) {
                final memberId = entry.value;
                final isMe = memberId == uid;
                final isMemberOwner = memberId == family.ownerId;
                final name = nicknames[memberId] ?? '멤버';
                final isLast = entry.key == family.memberIds.length - 1;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMe ? '$name (나)' : name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                        if (isMemberOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '방장',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary),
                            ),
                          ),
                      ],
                    ),
                    if (!isLast)
                      Divider(
                          height: 20,
                          color: Colors.black.withValues(alpha: 0.05)),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 나가기 / 해산 버튼
        OutlinedButton.icon(
          onPressed: loading ? null : onLeave,
          icon: Icon(
            isOwner
                ? Icons.delete_outline_rounded
                : Icons.exit_to_app_rounded,
            size: 18,
          ),
          label: Text(isOwner ? '그룹 해산' : '그룹 나가기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.expense,
            side: BorderSide(color: AppTheme.expense.withValues(alpha: 0.4)),
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
          Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
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
