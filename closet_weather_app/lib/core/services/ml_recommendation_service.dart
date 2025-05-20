import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
import '../models/outfit_model.dart';

/// Makine öğrenmesi API'sine bağlanarak akıllı kıyafet önerileri sunan servis
class MLRecommendationService {
  // Localde çalışan API URL - API'nin çalıştığı bilgisayarın gerçek IP adresi kullanılmalı
  // Aşağıdaki URL'lerden birini kullanabilirsiniz (yorumları kaldırın):
  
  // Android Emülatör için (localhost referansı):
  final String apiUrl = 'http://10.0.2.2:3000/api/recommend';
  
  // iOS Simulator için:
  // final String apiUrl = 'http://localhost:3000/api/recommend';
  
  // Fiziksel cihaz için (bilgisayarın gerçek IP adresi):
  // final String apiUrl = 'http://192.168.1.X:3000/api/recommend';
  
  /// Hava durumuna göre kıyafet kombinasyonu önerileri al
  Future<List<ClothingItemModel>> getOutfitRecommendation(
    String userId, 
    WeatherModel weather,
  ) async {
    debugPrint('🧠 ML API\'sine istek gönderiliyor...');
    debugPrint('📌 URL: $apiUrl');
    
    final requestBody = {
      'userId': userId,
      'weather': {
        'temperature': weather.temperature,
        'condition': weather.condition.toString().split('.').last.toLowerCase(),
        'description': weather.description,
      },
    };
    
    // Debug: İstek gövdesini yazdır
    debugPrint('📤 İstek: ${jsonEncode(requestBody)}');
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)); // 10 saniye zaman aşımı
      
      debugPrint('📡 API yanıtı: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // API'den gelen yanıtı doğrudan Flutter model nesnelerine dönüştür
        debugPrint('📥 Yanıt gövdesi: ${response.body.substring(0, min(100, response.body.length))}...');
        
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('📦 API ${data.length} kıyafet önerdi');
        
        final items = data.map((item) => ClothingItemModel.fromJson(item)).toList();
        debugPrint('✅ Kıyafet önerileri başarıyla alındı');
        return items;
      } else {
        // API hata durumunda
        debugPrint('❌ API hatası: ${response.statusCode}');
        debugPrint('Yanıt: ${response.body}');
        
        // Demo moduna geç
        debugPrint('⚠️ Demo modu kullanılıyor...');
        return _getDemoOutfit(weather);
      }
    } catch (e) {
      // Bağlantı sorunu veya diğer hatalar
      debugPrint('❌ API bağlantı hatası: $e');
      debugPrint('⚠️ Demo modu kullanılıyor...');
      
      // Demo moduna geç
      return _getDemoOutfit(weather);
    }
  }
  
  // Yanıt uzunluğunu sınırlamak için min fonksiyonu
  int min(int a, int b) => a < b ? a : b;
  
  /// API bağlantısı olmadığında kullanılacak demo kombini
  List<ClothingItemModel> _getDemoOutfit(WeatherModel weather) {
    final demoItems = <ClothingItemModel>[];
    final now = DateTime.now();
    
    // Debug: Demo modu aktivasyonu 
    debugPrint('🎭 Demo modu aktif - gerçek zamanlı hava durumu: ${weather.temperature}°C, ${weather.condition}');
    
    // Sıcaklığa göre farklı kombinler oluştur
    if (weather.temperature < 15) {
      // Soğuk hava kombini
      demoItems.add(ClothingItemModel(
        id: 'demo1',
        userId: 'demo_user',
        name: 'Gri Kazak',
        type: ClothingType.sweater,
        colors: ['#808080'],
        brand: 'Demo Brand',
        seasons: [Season.winter, Season.fall],
        createdAt: now,
        updatedAt: now,
      ));
      
      demoItems.add(ClothingItemModel(
        id: 'demo2',
        userId: 'demo_user',
        name: 'Lacivert Jean',
        type: ClothingType.jeans,
        colors: ['#000080'],
        brand: 'Demo Brand',
        seasons: [Season.all],
        createdAt: now,
        updatedAt: now,
      ));
      
      // Kötü hava durumu ise mont ekle
      if (weather.condition == WeatherCondition.rainy || 
          weather.condition == WeatherCondition.snowy ||
          weather.condition == WeatherCondition.stormy) {
        demoItems.add(ClothingItemModel(
          id: 'demo3',
          userId: 'demo_user',
          name: 'Siyah Mont',
          type: ClothingType.coat,
          colors: ['#000000'],
          brand: 'Demo Brand',
          seasons: [Season.winter],
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        demoItems.add(ClothingItemModel(
          id: 'demo3',
          userId: 'demo_user',
          name: 'Kot Ceket',
          type: ClothingType.jacket,
          colors: ['#0000FF'],
          brand: 'Demo Brand',
          seasons: [Season.fall, Season.spring],
          createdAt: now,
          updatedAt: now,
        ));
      }
      
      demoItems.add(ClothingItemModel(
        id: 'demo4',
        userId: 'demo_user',
        name: 'Siyah Bot',
        type: ClothingType.boots,
        colors: ['#000000'],
        brand: 'Demo Brand',
        seasons: [Season.winter, Season.fall],
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      // Sıcak hava kombini
      demoItems.add(ClothingItemModel(
        id: 'demo5',
        userId: 'demo_user',
        name: 'Beyaz T-Shirt',
        type: ClothingType.tShirt,
        colors: ['#FFFFFF'],
        brand: 'Demo Brand',
        seasons: [Season.summer],
        createdAt: now,
        updatedAt: now,
      ));
      
      if (weather.temperature > 25) {
        demoItems.add(ClothingItemModel(
          id: 'demo6',
          userId: 'demo_user',
          name: 'Mavi Şort',
          type: ClothingType.shorts,
          colors: ['#0000FF'],
          brand: 'Demo Brand',
          seasons: [Season.summer],
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        demoItems.add(ClothingItemModel(
          id: 'demo6',
          userId: 'demo_user',
          name: 'Bej Pantolon',
          type: ClothingType.pants,
          colors: ['#A52A2A'],
          brand: 'Demo Brand',
          seasons: [Season.spring, Season.summer],
          createdAt: now,
          updatedAt: now,
        ));
      }
      
      demoItems.add(ClothingItemModel(
        id: 'demo7',
        userId: 'demo_user',
        name: 'Spor Ayakkabı',
        type: ClothingType.shoes,
        colors: ['#FFFFFF', '#000000'],
        brand: 'Demo Brand',
        seasons: [Season.all],
        createdAt: now,
        updatedAt: now,
      ));
    }
    
    // Debug: Demo kıyafet sayısı
    debugPrint('👕 Demo kıyafet sayısı: ${demoItems.length}');
    
    return demoItems;
  }
} 