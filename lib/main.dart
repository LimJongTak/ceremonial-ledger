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
  KakaoSdk.init(nativeAppKey: '9e8cb74d18d1c54a5a7be9cd53461b56');
  runApp(const ProviderScope(child: CeremonialLedgerApp()));
}

class CeremonialLedgerApp extends ConsumerWidget {
  const CeremonialLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

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
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          // 로그인 됐으면 프로필 존재 여부 확인 후 분기
          return const _ProfileAwareHome();
        },
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
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
      loading: () => const SplashScreen(),
      error: (_, __) => const ProfileSetupScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '오고가고',
              style: TextStyle(
                fontFamily: 'NanumMiraenamu',
                fontSize: 48,
                color: Color(0xFF9a30ae),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '경조사 장부 플랫폼',
              style: TextStyle(
                fontFamily: 'GigiCheonnyeonBatang',
                fontSize: 18,
                color: Color(0xFFb96bc6),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF9a30ae),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
