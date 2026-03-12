import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../common/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _isLogin = true;
  bool _pwVisible = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isLoading = auth is AsyncLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        final msg = next.error.toString();
        if (msg.contains('PigeonUserDetails') || msg.contains('List<Object?>')) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Stack(children: [
        // 배경 장식 (subtle)
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primary.withValues(alpha: 0.08),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.secondary.withValues(alpha: 0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 52),

                    // 앱 로고
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('경조사 장부',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -1)),
                    const SizedBox(height: 6),
                    const Text('소중한 인연을 기록하세요',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary)),

                    const SizedBox(height: 40),

                    // 로그인 / 회원가입 탭
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        _TabBtn(
                            label: '로그인',
                            isActive: _isLogin,
                            onTap: () {
                              setState(() => _isLogin = true);
                              _formKey.currentState?.reset();
                            }),
                        _TabBtn(
                            label: '회원가입',
                            isActive: !_isLogin,
                            onTap: () {
                              setState(() => _isLogin = false);
                              _formKey.currentState?.reset();
                            }),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // 이메일 입력
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        prefixIconColor: AppTheme.textSecondary,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return '유효한 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // 비밀번호 입력
                    TextFormField(
                      controller: _pwCtrl,
                      obscureText: !_pwVisible,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20),
                        prefixIconColor: AppTheme.textSecondary,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _pwVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20),
                          onPressed: () =>
                              setState(() => _pwVisible = !_pwVisible),
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                        if (!_isLogin && v.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),

                    // 비밀번호 찾기 (로그인 모드에서만 표시)
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _showForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                          ),
                          child: const Text(
                            '비밀번호를 잊으셨나요?',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),

                    // 이메일 로그인/회원가입 버튼
                    _PrimaryBtn(
                      onTap: isLoading ? null : _handleEmailAuth,
                      loading: isLoading,
                      label: _isLogin ? '로그인' : '회원가입',
                    ),

                    const SizedBox(height: 20),

                    // 구분선
                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey[200])),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('또는',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ]),

                    const SizedBox(height: 20),

                    // Google
                    _SocialBtn(
                      onTap: isLoading
                          ? null
                          : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInWithGoogle(),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 24,
                                  color: Color(0xFF4285F4)),
                            ),
                            const SizedBox(width: 10),
                            const Text('Google로 계속하기',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                          ]),
                    ),

                    const SizedBox(height: 10),

                    // 카카오
                    _SocialBtn(
                      onTap: isLoading
                          ? null
                          : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInWithKakao(),
                      backgroundColor: const Color(0xFFFEE500),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3C1E1E),
                              ),
                              child: const Center(
                                child: Text('K',
                                    style: TextStyle(
                                        color: Color(0xFFFEE500),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('카카오로 계속하기',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3C1E1E))),
                          ]),
                    ),

                    const SizedBox(height: 10),

                    // 네이버
                    _SocialBtn(
                      onTap: isLoading
                          ? null
                          : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInWithNaver(),
                      backgroundColor: const Color(0xFF03C75A),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Text('N',
                                    style: TextStyle(
                                        color: Color(0xFF03C75A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('네이버로 계속하기',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ]),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _handleEmailAuth() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text.trim();
    if (_isLogin) {
      ref.read(authNotifierProvider.notifier).signInWithEmail(email, pw);
    } else {
      ref.read(authNotifierProvider.notifier).createAccount(email, pw);
    }
  }

  void _showForgotPassword() {
    final resetEmailCtrl =
        TextEditingController(text: _emailCtrl.text.trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '비밀번호 재설정',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                '가입한 이메일 주소로 재설정 링크를 보내드립니다.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일',
                  prefixIcon:
                      const Icon(Icons.email_outlined, size: 20),
                  prefixIconColor: AppTheme.textSecondary,
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
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final email = resetEmailCtrl.text.trim();
                    if (email.isEmpty) return;
                    Navigator.pop(context);
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .sendPasswordReset(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$email 으로 재설정 링크를 보냈습니다'),
                            backgroundColor: AppTheme.income,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: AppTheme.expense,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('재설정 링크 전송'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공통 위젯 ──────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  )),
            ),
          ),
        ),
      );
}

// 그라데이션 제거 → 단색 프라이머리 버튼
class _PrimaryBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final String label;
  const _PrimaryBtn(
      {required this.onTap, required this.loading, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      );
}

class _SocialBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? backgroundColor;
  const _SocialBtn(
      {required this.onTap,
      required this.child,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: backgroundColor == null
                ? Border.all(color: Colors.grey[200]!)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: child,
        ),
      );
}
