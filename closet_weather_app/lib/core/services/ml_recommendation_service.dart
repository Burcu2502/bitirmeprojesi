import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
import '../models/outfit_model.dart';
import '../config/env.dart';

/// Makine öğrenmesi API'sine bağlanarak akıllı kıyafet önerileri sunan servis
class MLRecommendationService {
  // Eski endpoint'leri kaldırıp Environment'tan alıyoruz
  final String apiUrl = Environment.mlRecommendationApi;
  final String multipleApiUrl = Environment.mlMultipleRecommendationApi;
  
  /// Hava durumuna göre kıyafet kombinasyonu önerileri al
  Future<List<ClothingItemModel>> getOutfitRecommendation(
    String userId, 
    WeatherModel weather,
    List<ClothingItemModel> userClothingItems,
  ) async {
    debugPrint('🧠 ML API\'sine istek gönderiliyor...');
    debugPrint('📌 URL: $apiUrl');
    debugPrint('👕 Gönderilen kıyafet sayısı: ${userClothingItems.length}');
    
    // Kullanıcının kıyafetlerini API formatına dönüştür
    final clothingItemsJson = userClothingItems.map((item) => {
      'id': item.id,
      'userId': item.userId,
      'name': item.name,
      'type': item.type.toString().split('.').last,
      'colors': item.colors,
      'brand': item.brand,
      'seasons': item.seasons.map((s) => s.toString().split('.').last).toList(),
      'imageUrl': item.imageUrl,
    }).toList();
    
    final requestBody = {
      'userId': userId,
      'weather': {
        'temperature': weather.temperature,
        'condition': weather.condition.toString().split('.').last.toLowerCase(),
        'description': weather.description,
      },
      'userClothingItems': clothingItemsJson,
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
        
        final items = data.map((item) => ClothingItemModel.fromApiJson(item)).toList();
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

  /// Genel katalogdan (demo veriler) kıyafet önerisi al - Hava durumu ekranı için
  Future<List<ClothingItemModel>> getOutfitRecommendationFromCatalog(
    String userId, 
    WeatherModel weather,
  ) async {
    debugPrint('🧠 ML API\'sine katalog önerisi isteği gönderiliyor...');
    debugPrint('📌 URL: $apiUrl');
    debugPrint('🏪 Genel katalog kullanılıyor (demo veriler)');
    
    final requestBody = {
      'userId': userId,
      'weather': {
        'temperature': weather.temperature,
        'condition': weather.condition.toString().split('.').last.toLowerCase(),
        'description': weather.description,
      },
      // userClothingItems gönderme - API demo verileri kullanacak
    };
    
    debugPrint('📤 İstek: ${jsonEncode(requestBody)}');
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📡 Katalog API yanıtı: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('📥 Yanıt gövdesi: ${response.body.substring(0, min(100, response.body.length))}...');
        
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('📦 Katalog API ${data.length} kıyafet önerdi');
        
        final items = data.map((item) => ClothingItemModel.fromApiJson(item)).toList();
        debugPrint('✅ Katalog önerileri başarıyla alındı');
        return items;
      } else {
        debugPrint('❌ Katalog API hatası: ${response.statusCode}');
        debugPrint('Yanıt: ${response.body}');
        
        // Demo moduna geç
        debugPrint('⚠️ Demo modu kullanılıyor...');
        return _getDemoOutfit(weather);
      }
    } catch (e) {
      debugPrint('❌ Katalog API bağlantı hatası: $e');
      debugPrint('⚠️ Demo modu kullanılıyor...');
      
      return _getDemoOutfit(weather);
    }
  }

  /// Çoklu strateji ile kıyafet önerileri al (4 farklı algoritma)
  Future<List<Map<String, dynamic>>> getMultipleOutfitRecommendations(
    String userId, 
    WeatherModel weather,
    List<ClothingItemModel> userClothingItems,
  ) async {
    // Sadece kritik bilgileri logla
    debugPrint('🧠 ML API çoklu öneri isteği: ${userClothingItems.length} kıyafet');
    
    // Kullanıcının kıyafetlerini API formatına dönüştür
    final clothingItemsJson = userClothingItems.map((item) => {
      'id': item.id,
      'userId': item.userId,
      'name': item.name,
      'type': item.type.toString().split('.').last,
      'colors': item.colors,
      'brand': item.brand,
      'seasons': item.seasons.map((s) => s.toString().split('.').last).toList(),
      'imageUrl': item.imageUrl,
    }).toList();
    
    final requestBody = {
      'userId': userId,
      'weather': {
        'temperature': weather.temperature,
        'condition': weather.condition.toString().split('.').last.toLowerCase(),
        'description': weather.description,
      },
      'userClothingItems': clothingItemsJson, // ← KULLANICININ GERÇEK KIYAFETLERİ
    };
    
    try {
      final response = await http.post(
        Uri.parse(multipleApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)); // 15 saniye zaman aşımı
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Her strateji için kıyafetleri Flutter modellerine dönüştür
        final recommendations = <Map<String, dynamic>>[];
        
        for (final strategy in data) {
          final items = (strategy['items'] as List<dynamic>)
              .map((item) => ClothingItemModel.fromApiJson(item))
              .toList();
          
          recommendations.add({
            'title': strategy['title'] ?? 'AI Önerisi',
            'description': strategy['description'] ?? 'AI ile oluşturulan kombin',
            'strategy': strategy['strategy'] ?? 'unknown',
            'items': items,
          });
        }
        
        return recommendations;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
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