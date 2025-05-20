import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mevcut dil tercihi anahtarı
const String _localePreferenceKey = 'app_locale';

// Dil sağlayıcı - Artık kullanılmayacak, Easy Localization kullanılacak
final localeProvider = Provider<Locale>((ref) {
  return const Locale('tr', 'TR'); // Varsayılan olarak Türkçe
}); 