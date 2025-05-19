import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firebase App Check'i başlat - Debug modunda çalıştığından hata mesajları görmezden gelinecek
  try {
    await FirebaseAppCheck.instance.activate(
      // Debug provider'ı ilk sıraya alarak öncelik veriyoruz
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
    debugPrint("✅ Firebase App Check başarıyla etkinleştirildi");
  } catch (e) {
    // Geliştirme ortamında App Check hataları kritik değil, devam edebiliriz
    debugPrint("⚠️ Firebase App Check etkinleştirilemedi: $e");
    debugPrint("ℹ️ Geliştirme ortamında bu hata görmezden gelinebilir");
  }
  
  runApp(
    const ProviderScope(
      child: ClosetWeatherApp(),
    ),
  );
}

class ClosetWeatherApp extends ConsumerWidget {
  const ClosetWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Dolap & Hava Durumu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
