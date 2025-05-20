import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/providers/theme_provider.dart' as app_theme;
import 'core/providers/locale_provider.dart';
import 'shared/theme/app_theme.dart'; // AppTheme sınıfını import ediyoruz

// Ana uygulama başlangıç noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Firebase'i başlat - çift başlatma hatasını önle
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase başarıyla başlatıldı");
    } else {
      Firebase.app(); // Zaten başlatılmışsa mevcut uygulamayı kullan
      debugPrint("ℹ️ Firebase zaten başlatılmış, mevcut örnek kullanılıyor");
    }
    
    // Firebase Auth'ın mevcut oturum durumunu kontrol et
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint("🔄 Firebase Auth kontrol edildi: ${currentUser != null ? 'Oturum açık' : 'Oturum kapalı'}");
    if (currentUser != null) {
      debugPrint("✅ Mevcut kullanıcı bulundu: ${currentUser.uid}, ${currentUser.email}");
    }
    
    // Firebase App Check'i başlat - Debug modunda çalıştırıyoruz
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      debugPrint("✅ Firebase App Check başarıyla etkinleştirildi");
    } catch (e) {
      // Geliştirme ortamında App Check hataları kritik değil, devam edebiliriz
      debugPrint("⚠️ Firebase App Check etkinleştirilemedi: $e");
      debugPrint("ℹ️ Geliştirme ortamında bu hata görmezden gelinebilir");
    }
  } catch (e) {
    debugPrint("❌ Firebase başlatılırken hata oluştu: $e");
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

class ClosetWeatherApp extends ConsumerWidget {
  const ClosetWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema sağlayıcısı
    final themeMode = ref.watch(app_theme.themeProvider);
    
    debugPrint("🌐 Şu anki dil: ${context.locale.languageCode}_${context.locale.countryCode}");
    
    // Flutter'ın kendi ThemeMode sınıfına dönüştür
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
    
    return MaterialApp(
      title: 'appTitle'.tr(),
      debugShowCheckedModeBanner: false,
      
      // Özel tema ayarları
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      
      // Easy Localization ayarları
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      
      home: const SplashScreen(),
    );
  }
}
                                      