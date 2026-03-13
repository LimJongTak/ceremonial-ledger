import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'views/home/main_nav_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/profile_setup_screen.dart';
import 'views/common/app_theme.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';
// TODO: FCM 활성화 시 주석 해제 (Firebase Blaze 플랜 필요)
// import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 투명하게
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 이미 초기화된 경우 무시
  }
  await HomeWidgetService.instance.initialize();
  await NotificationService.instance.initialize();
  // TODO: FCM 활성화 시 주석 해제 (Firebase Blaze 플랜 필요)
  // await FcmService.instance.initialize();
  KakaoSdk.init(nativeAppKey: '9e8cb74d18d1c54a5a7be9cd53461b56');
  runApp(const ProviderScope(child: CeremonialLedgerApp()));
}

class CeremonialLedgerApp extends ConsumerWidget {
  const CeremonialLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '경조사 장부',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      theme: AppTheme.light,
      home: const _AppRoot(),
    );
  }
}

// 스플래시 완료 여부를 로컬 state로 관리 — 전역 provider 불필요
class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _splashDone = false;

  void _onSplashDone() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onDone: _onSplashDone);
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) =>
          user == null ? const LoginScreen() : const _ProfileAwareHome(),
      loading: () => const Scaffold(backgroundColor: Colors.white),
      error: (_, __) => const LoginScreen(),
    );
  }
}

// 프로필 유무에 따라 ProfileSetupScreen 또는 MainNavScreen으로 분기
class _ProfileAwareHome extends ConsumerWidget {
  const _ProfileAwareHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) =>
          profile == null ? const ProfileSetupScreen() : const MainNavScreen(),
      loading: () => const Scaffold(backgroundColor: Colors.white),
      error: (_, __) => const ProfileSetupScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // 오고가고 4글자 각각 stagger
  late final List<Animation<double>> _charFades;

  // 경조사 장부 플랫폼: 글자보다 먼저 나타남
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleOffset;

  static const _titleChars = ['오', '고', '가', '고'];

  // 서브타이틀(0~10%) 먼저 → 글자 8%부터 14% 간격으로 천천히 등장
  static const _charStarts = [0.08, 0.22, 0.36, 0.50];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _charFades = _charStarts
        .map((start) => CurvedAnimation(
              parent: _ctrl,
              curve: Interval(start, start + 0.18, curve: Curves.easeOut),
            ))
        .toList();

    // 서브타이틀: 글자보다 먼저 시작해 빠르게 완료
    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
    );
    _subtitleOffset = Tween<double>(begin: 22.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.16, curve: Curves.easeOutCubic),
      ),
    );

    // 애니메이션 완료 후 2초 뒤 홈 화면으로 전환
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onDone();
        });
      }
    });

    // 앱 실행 1초 후 애니메이션 시작
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 오고가고 - 한 글자씩 페이드인
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_titleChars.length, (i) {
                    return FadeTransition(
                      opacity: _charFades[i],
                      child: Text(
                        _titleChars[i],
                        style: const TextStyle(
                          fontFamily: 'NanumMiraenamu',
                          fontSize: 66,
                          color: Color(0xFF9a30ae),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // 경조사 장부 플랫폼 - 위로 슬라이드 + 페이드인
                Transform.translate(
                  offset: Offset(0, _subtitleOffset.value),
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      '경조사 장부 플랫폼',
                      style: TextStyle(
                        fontFamily: 'GigiCheonnyeonBatang',
                        fontSize: 26,
                        color: Color(0xFF9a30ae),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
