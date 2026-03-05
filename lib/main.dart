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
  KakaoSdk.init(nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY');
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
      theme: AppTheme.light, // ← 새 테마 적용
      home: authState.when(
        data: (user) =>
            user != null ? const MainNavScreen() : const LoginScreen(),
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('💝', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '경조사 장부',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text('소중한 인연을 기록하세요',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
