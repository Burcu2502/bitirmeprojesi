import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/providers/theme_provider.dart' as app_theme;
import 'core/providers/locale_provider.dart';
import 'shared/theme/app_theme.dart'; // AppTheme sınıfını import ediyoruz
import 'core/services/connectivity_service.dart';

// Ana uygulama başlangıç noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // EasyLocalization'ı düzgün başlat
  await EasyLocalization.ensureInitialized();
  
  // Firebase'i basit şekilde başlat (Google Play Services hatası için)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase başlatıldı");
  } catch (e) {
    debugPrint("❌ Firebase başlatma hatası: $e");
    // Hata olsa bile uygulamayı başlat
  }
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr', 'TR'),
      child: const ProviderScope(
        child: ClosetWeatherApp(),
      ),
    ),
  );
}

class ClosetWeatherApp extends ConsumerStatefulWidget {
  const ClosetWeatherApp({super.key});

  @override
  _ClosetWeatherAppState createState() => _ClosetWeatherAppState();
}

class _ClosetWeatherAppState extends ConsumerState<ClosetWeatherApp> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(app_theme.themeProvider);
    
    debugPrint("🌐 Şu anki dil: ${context.locale.languageCode}_${context.locale.countryCode}");
    
    late ThemeMode flutterThemeMode;
    switch (themeMode) {
      case app_theme.ThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case app_theme.ThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case app_theme.ThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
    }
    
    return ScaffoldMessenger(
      child: MaterialApp(
        title: 'appTitle'.tr(),
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: flutterThemeMode,
        
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        
        home: Builder(
          builder: (context) {
            // ConnectivityService'i burada başlat
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _connectivityService.initialize(context);
            });
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}
                                      