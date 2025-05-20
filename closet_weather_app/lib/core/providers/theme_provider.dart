import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tema modu
enum ThemeMode {
  system, // Sistem ayarlarına göre
  light,  // Açık tema
  dark,   // Koyu tema
}

// Tema sağlayıcı
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Varsayılan olarak sistem ayarlarını kullan
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  // Tema tercihini SharedPreferences'dan yükle
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString('theme_mode');
      
      if (themeString != null) {
        switch (themeString) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          default:
            state = ThemeMode.system;
        }
      }
      debugPrint('✅ Tema tercihi yüklendi: $state');
    } catch (e) {
      debugPrint('❌ Tema tercihi yüklenirken hata: $e');
    }
  }

  // Tema tercihini değiştir ve kaydet
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        default:
          themeString = 'system';
      }
      
      await prefs.setString('theme_mode', themeString);
      debugPrint('✅ Tema tercihi kaydedildi: $themeString');
    } catch (e) {
      debugPrint('❌ Tema tercihi kaydedilirken hata: $e');
    }
  }
} 