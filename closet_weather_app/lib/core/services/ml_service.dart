import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
import '../models/outfit_model.dart';
import 'color_analysis_service.dart';

/// Makine öğrenmesi modellerini yöneten ve kıyafet analizi/önerisi yapan servis
class MLService {
  final ColorAnalysisService _colorAnalysisService = ColorAnalysisService();
  
  /// Görüntüden kıyafet tipini tahmin et
  Future<ClothingType> predictClothingType(File imageFile) async {
    // NOT: Gerçek TensorFlow Lite modeli ile entegrasyon burada yapılacak
    // Şu anda basit bir demo sunuyoruz
    
    // Demo için rastgele bir kıyafet tipi döndür
    final random = Random();
    final types = ClothingType.values;
    return types[random.nextInt(types.length)];
  }
  
  /// Görüntüden mevsim tahmini yap
  Future<List<Season>> predictSeasons(File imageFile, ClothingType type) async {
    // Gerçek uygulamada bu TensorFlow Lite ile yapılacak
    // Şimdilik basit bir ağırlıklı rastgele tahmin
    
    final random = Random();
    final List<Season> predictedSeasons = [];
    
    // Kıyafet tipine göre mevsim olasılıklarını belirle
    Map<Season, double> seasonProbabilities = {};
    
    switch (type) {
      case ClothingType.tShirt:
      case ClothingType.shorts:
        // Yazlık kıyafetler için yaz ve ilkbahar daha olası
        seasonProbabilities = {
          Season.summer: 0.7,
          Season.spring: 0.4,
          Season.fall: 0.2,
          Season.winter: 0.0,
        };
        break;
        
      case ClothingType.coat:
      case ClothingType.boots:
        // Kışlık kıyafetler için kış ve sonbahar daha olası
        seasonProbabilities = {
          Season.winter: 0.8,
          Season.fall: 0.5,
          Season.spring: 0.2,
          Season.summer: 0.0,
        };
        break;
        
      case ClothingType.sweater:
        // Kazaklar için sonbahar, kış ve ilkbahar daha olası
        seasonProbabilities = {
          Season.winter: 0.6,
          Season.fall: 0.7,
          Season.spring: 0.4,
          Season.summer: 0.1,
        };
        break;
        
      default:
        // Diğer kıyafetler için daha dengeli olasılıklar
        seasonProbabilities = {
          Season.winter: 0.4,
          Season.fall: 0.4,
          Season.spring: 0.4,
          Season.summer: 0.4,
        };
    }
    
    // Olasılıklara göre her mevsimi ekle veya ekleme
    seasonProbabilities.forEach((season, probability) {
      if (random.nextDouble() < probability) {
        predictedSeasons.add(season);
      }
    });
    
    // Hiçbir mevsim seçilmediyse, en az bir tane seç
    if (predictedSeasons.isEmpty) {
      final seasons = seasonProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      predictedSeasons.add(seasons.first.key);
    }
    
    return predictedSeasons;
  }
  
  /// Görüntüden renk çıkarımı yap
  Future<List<String>> extractColorsFromImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final colors = await _colorAnalysisService.extractDominantColors(bytes);
      
      // Çıkarılan renkleri hex formatına dönüştür
      return colors.map((color) {
        // #RRGGBB formatında hex kod
        final hex = '#${color.value.toRadixString(16).substring(2, 8)}';
        return hex;
      }).toList();
    } catch (e) {
      debugPrint('Renk çıkarımı sırasında hata: $e');
      return ['#000000']; // Varsayılan olarak siyah
    }
  }
  
  /// Renk uyumuna göre kombin önerisi yap
  Future<List<ClothingItemModel>> suggestOutfitByColorHarmony(
    List<ClothingItemModel> availableItems,
    ClothingItemModel baseItem,
    int maxItems,
  ) async {
    if (availableItems.isEmpty || baseItem.colors.isEmpty) {
      return [];
    }
    
    final List<MapEntry<ClothingItemModel, double>> scoredItems = [];
    
    // Temel kıyafetin renklerini analiz et
    final baseColors = baseItem.colors.map((hex) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }).toList();
    
    // Her kıyafet için renk uyum skoru hesapla
    for (final item in availableItems) {
      // Kendisini önerme
      if (item.id == baseItem.id) continue;
      
      // Aynı tip kıyafetleri önerme (iki pantolon, iki gömlek gibi)
      if (_isSameCategory(item.type, baseItem.type)) continue;
      
      double score = 0;
      
      // Renk uyumunu değerlendir
      for (final itemColorHex in item.colors) {
        try {
          final itemColor = Color(int.parse(itemColorHex.replaceFirst('#', '0xFF')));
          
          for (final baseColor in baseColors) {
            final harmony = _calculateColorHarmony(baseColor, itemColor);
            score += harmony;
          }
        } catch (e) {
          // Geçersiz renk kodu, yoksay
        }
      }
      
      // Ortalama skor
      if (item.colors.isNotEmpty && baseColors.isNotEmpty) {
        score = score / (item.colors.length * baseColors.length);
      }
      
      scoredItems.add(MapEntry(item, score));
    }
    
    // Skora göre sırala
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    
    // En iyi eşleşmeleri döndür (maxItems kadar)
    final recommendations = scoredItems.take(maxItems).map((e) => e.key).toList();
    
    // Temel öğeyi de dahil et
    return [baseItem, ...recommendations];
  }
  
  /// İki renk arasındaki uyum skorunu hesapla
  double _calculateColorHarmony(Color c1, Color c2) {
    // Renk mesafesi (düşük mesafe = yüksek uyum)
    final distance = _colorDistance(c1, c2);
    
    // Mesafeyi [0-1] aralığına normalize et (ters ölçek, 0 = en uzak, 1 = en yakın)
    double normalizedDistance = 1.0 - min(1.0, distance / 450.0);
    
    // Monokromatik uyumu kontrol et (aynı ton, farklı doygunluk/parlaklık)
    final HSLColor hsl1 = HSLColor.fromColor(c1);
    final HSLColor hsl2 = HSLColor.fromColor(c2);
    
    final hueDiff = (hsl1.hue - hsl2.hue).abs();
    final isMonochromatic = hueDiff < 15.0 || hueDiff > 345.0;
    
    if (isMonochromatic) {
      // Yeterince farklı parlaklıklar varsa bonus
      final lightnessDiff = (hsl1.lightness - hsl2.lightness).abs();
      if (lightnessDiff > 0.2) {
        normalizedDistance += 0.2;
      }
    }
    
    // Tamamlayıcı renkler (yaklaşık 180 derece farklı)
    final isComplementary = hueDiff > 165.0 && hueDiff < 195.0;
    if (isComplementary) {
      normalizedDistance += 0.3;
    }
    
    // Uçluk renk kontrastı (siyah, beyaz, vs.)
    if ((hsl1.lightness < 0.1 && hsl2.lightness > 0.9) || 
        (hsl1.lightness > 0.9 && hsl2.lightness < 0.1)) {
      normalizedDistance += 0.2;
    }
    
    return min(1.0, normalizedDistance); // 0-1 aralığında sınırla
  }
  
  /// İki renk arasındaki mesafeyi hesapla (daha düşük = daha benzer)
  double _colorDistance(Color c1, Color c2) {
    final rmean = (c1.red + c2.red) / 2;
    final r = c1.red - c2.red;
    final g = c1.green - c2.green;
    final b = c1.blue - c2.blue;
    
    // Ağırlıklı Euclidean mesafesi (insan algısına göre düzenlenmiş)
    return sqrt((2 + rmean / 256) * r * r + 4 * g * g + (2 + (255 - rmean) / 256) * b * b);
  }
  
  /// İki kıyafet tipinin aynı kategoride olup olmadığını kontrol et
  bool _isSameCategory(ClothingType type1, ClothingType type2) {
    // Üst giyim
    final upperClothing = [
      ClothingType.tShirt, 
      ClothingType.shirt, 
      ClothingType.blouse, 
      ClothingType.sweater
    ];
    
    // Alt giyim
    final lowerClothing = [
      ClothingType.pants, 
      ClothingType.jeans, 
      ClothingType.shorts, 
      ClothingType.skirt
    ];
    
    // Dış giyim
    final outerClothing = [
      ClothingType.jacket,
      ClothingType.coat
    ];
    
    // Ayakkabı
    final footwear = [
      ClothingType.shoes,
      ClothingType.boots
    ];
    
    // Aksesuar
    final accessories = [
      ClothingType.accessory,
      ClothingType.hat,
      ClothingType.scarf
    ];
    
    // Tek parça
    final onepiece = [
      ClothingType.dress
    ];
    
    // Her iki tip de aynı kategoride mi?
    return (upperClothing.contains(type1) && upperClothing.contains(type2)) ||
           (lowerClothing.contains(type1) && lowerClothing.contains(type2)) ||
           (outerClothing.contains(type1) && outerClothing.contains(type2)) ||
           (footwear.contains(type1) && footwear.contains(type2)) ||
           (accessories.contains(type1) && accessories.contains(type2)) ||
           (onepiece.contains(type1) && onepiece.contains(type2));
  }
  
  /// Hava durumuna en uygun kıyafet tiplerini belirle
  List<ClothingType> getSuitableClothingTypesForWeather(WeatherModel weather) {
    final temperature = weather.temperature;
    final List<ClothingType> suitableTypes = [];
    
    // Hava sıcaklığına göre öneriler
    if (temperature < 5) {
      // Çok soğuk
      suitableTypes.addAll([
        ClothingType.coat,
        ClothingType.sweater,
        ClothingType.pants,
        ClothingType.jeans,
        ClothingType.boots,
        ClothingType.hat,
        ClothingType.scarf,
      ]);
    } else if (temperature < 15) {
      // Soğuk
      suitableTypes.addAll([
        ClothingType.jacket,
        ClothingType.sweater,
        ClothingType.shirt,
        ClothingType.pants,
        ClothingType.jeans,
        ClothingType.boots,
      ]);
    } else if (temperature < 25) {
      // Ilıman
      suitableTypes.addAll([
        ClothingType.shirt,
        ClothingType.tShirt,
        ClothingType.pants,
        ClothingType.jeans,
        ClothingType.skirt,
        ClothingType.dress,
        ClothingType.shoes,
      ]);
    } else {
      // Sıcak
      suitableTypes.addAll([
        ClothingType.tShirt,
        ClothingType.shorts,
        ClothingType.skirt,
        ClothingType.dress,
        ClothingType.shoes,
      ]);
    }
    
    // Yağış durumuna göre ek öneriler
    if (weather.condition == WeatherCondition.rainy || 
        weather.condition == WeatherCondition.stormy) {
      suitableTypes.add(ClothingType.coat);
      suitableTypes.add(ClothingType.boots);
    }
    
    return suitableTypes;
  }
} 