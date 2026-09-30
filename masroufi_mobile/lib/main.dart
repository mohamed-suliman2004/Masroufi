import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/state/app_state.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.init();
  await AppState.instance.init();
  await SmsService.instance.init();
  runApp(const MasroufiApp());
}

class MasroufiApp extends StatelessWidget {
  const MasroufiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'مصروفي',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'LY'),
            Locale('ar', ''),
            Locale('en', ''),
          ],
          locale: const Locale('ar', 'LY'),
          home: !AppState.instance.isLoggedIn
              ? const LoginScreen()
              : (!AppState.instance.hasSeenOnboarding
                  ? const OnboardingScreen()
                  : const HomeScreen()),
        );
      },
    );
  }
}
