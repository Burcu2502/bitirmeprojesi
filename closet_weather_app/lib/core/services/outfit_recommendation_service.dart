import 'dart:math';
import 'package:flutter/material.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';
import '../models/weather_model.dart';
import 'color_analysis_service.dart';

class OutfitRecommendationService {
  final ColorAnalysisService _colorAnalysisService = ColorAnalysisService();
  
  // Hava durumuna göre kombin önerisi
  List<ClothingItemModel> recommendOutfitForWeather(
    List<ClothingItemModel> availableItems, 
    WeatherModel weather,
    {String? skinTone}
  ) {
    // Debug başlangıcı
    debugPrint("💡 Kombin önerisi oluşturuluyor...");
    debugPrint("🌡️ Hava durumu: ${weather.temperature}°C, ${weather.condition}, ${weather.description}");
    
    // Kıyafet kontrolü - eğer hiç kıyafet yoksa boş liste döndür
    if (availableItems.isEmpty) {
      debugPrint("⚠️ Hiç kıyafet bulunamadı");
      return [];
    }

    debugPrint("👕 Toplam kıyafet sayısı: ${availableItems.length}");

    // Hava durumuna uygun kıyafet tiplerini belirle
    final List<ClothingType> suitableTypes = _getSuitableClothingTypes(weather);
    debugPrint("📋 Uygun kıyafet tipleri: $suitableTypes");
    
    // Hava durumuna uygun mevsimleri belirle (Tüm Sezonlar dahil)
    final List<Season> suitableSeasons = _getSuitableSeasonsForWeather(weather);
    // Her zaman tüm sezonları kabul et
    if (!suitableSeasons.contains(Season.all)) {
      suitableSeasons.add(Season.all);
    }
    
    // DEBUG: Mevsimler hakkında log
    debugPrint("🌍 Hava durumuna uygun mevsimler: $suitableSeasons");
    
    try {
      // Uygun üst giyim kıyafetlerini filtrele
      var uppers = availableItems.where((item) => 
        _isUpperClothing(item.type)
      ).toList();
      
      // Sezon ve tipe göre sırala
      uppers.sort((a, b) {
        // Önce uygun mevsimde olanları tercih et
        bool aHasMatchingSeason = a.seasons.any((s) => suitableSeasons.contains(s));
        bool bHasMatchingSeason = b.seasons.any((s) => suitableSeasons.contains(s));
        
        if (aHasMatchingSeason && !bHasMatchingSeason) return -1;
        if (!aHasMatchingSeason && bHasMatchingSeason) return 1;
        
        // Sonra uygun tipe göre sırala
        bool aHasMatchingType = suitableTypes.contains(a.type);
        bool bHasMatchingType = suitableTypes.contains(b.type);
        
        if (aHasMatchingType && !bHasMatchingType) return -1;
        if (!aHasMatchingType && bHasMatchingType) return 1;
        
        return 0;
      });
      
      debugPrint("👚 Filtrelenmiş üst giyim sayısı: ${uppers.length}");
      
      // Uygun alt giyim kıyafetlerini filtrele
      var lowers = availableItems.where((item) => 
        _isLowerClothing(item.type)
      ).toList();
      
      // Sezon ve tipe göre sırala
      lowers.sort((a, b) {
        // Önce uygun mevsimde olanları tercih et
        bool aHasMatchingSeason = a.seasons.any((s) => suitableSeasons.contains(s));
        bool bHasMatchingSeason = b.seasons.any((s) => suitableSeasons.contains(s));
        
        if (aHasMatchingSeason && !bHasMatchingSeason) return -1;
        if (!aHasMatchingSeason && bHasMatchingSeason) return 1;
        
        // Sonra uygun tipe göre sırala
        bool aHasMatchingType = suitableTypes.contains(a.type);
        bool bHasMatchingType = suitableTypes.contains(b.type);
        
        if (aHasMatchingType && !bHasMatchingType) return -1;
        if (!aHasMatchingType && bHasMatchingType) return 1;
        
        return 0;
      });
      
      debugPrint("👖 Filtrelenmiş alt giyim sayısı: ${lowers.length}");
      
      // Uygun ayakkabıları filtrele
      var shoes = availableItems.where((item) => 
        (item.type == ClothingType.shoes || item.type == ClothingType.boots)
      ).toList();
      
      // Sezon ve tipe göre sırala
      shoes.sort((a, b) {
        // Önce uygun mevsimde olanları tercih et
        bool aHasMatchingSeason = a.seasons.any((s) => suitableSeasons.contains(s));
        bool bHasMatchingSeason = b.seasons.any((s) => suitableSeasons.contains(s));
        
        if (aHasMatchingSeason && !bHasMatchingSeason) return -1;
        if (!aHasMatchingSeason && bHasMatchingSeason) return 1;
        
        // Sonra bot mu ayakkabı mı diye sırala
        if (weather.temperature < 15 && a.type == ClothingType.boots) return -1;
        if (weather.temperature < 15 && b.type == ClothingType.boots) return 1;
        
        return 0;
      });
      
      debugPrint("👞 Filtrelenmiş ayakkabı sayısı: ${shoes.length}");
      
      // Uygun dış giyimleri filtrele
      var outwear = availableItems.where((item) => 
        _isOuterwear(item.type)
      ).toList();
      
      // Sıcaklık ve mevsime göre sırala
      outwear.sort((a, b) {
        // Önce uygun mevsimde olanları tercih et
        bool aHasMatchingSeason = a.seasons.any((s) => suitableSeasons.contains(s));
        bool bHasMatchingSeason = b.seasons.any((s) => suitableSeasons.contains(s));
        
        if (aHasMatchingSeason && !bHasMatchingSeason) return -1;
        if (!aHasMatchingSeason && bHasMatchingSeason) return 1;
        
        return 0;
      });
      
      // Eğer yeterli kıyafet yoksa boş liste döndür
      if (uppers.isEmpty && lowers.isEmpty) {
        debugPrint("⚠️ Yeterli kıyafet bulunamadı, kombin oluşturulamadı");
        return [];
      }
      
      // Renk uyumuna göre kombin oluştur
      List<ClothingItemModel> recommendation = [];
      
      // Üst giyim ekle
      if (uppers.isNotEmpty) {
        recommendation.add(uppers.first);
        debugPrint("👚 Üst giyim eklendi: ${uppers.first.name} (${uppers.first.id})");
      }
      
      // Alt giyim ekle
      if (lowers.isNotEmpty) {
        recommendation.add(lowers.first);
        debugPrint("👖 Alt giyim eklendi: ${lowers.first.name} (${lowers.first.id})");
      }
      
      // Hava durumuna göre dış giyim ekle
      if (outwear.isNotEmpty && _needsOuterwear(weather)) {
        recommendation.add(outwear.first);
        debugPrint("🧥 Dış giyim eklendi: ${outwear.first.name} (${outwear.first.id})");
      }
      
      // Ayakkabı ekle
      if (shoes.isNotEmpty) {
        recommendation.add(shoes.first);
        debugPrint("👞 Ayakkabı eklendi: ${shoes.first.name} (${shoes.first.id})");
      }
      
      debugPrint("✅ Kombin önerisi tamamlandı, ${recommendation.length} parça");
      for (var item in recommendation) {
        debugPrint("  - ${item.name} (${item.type})");
      }
      
      return recommendation;
    } catch (e) {
      debugPrint("❌ Kombin önerisinde hata: $e");
      return [];
    }
  }
  
  // Üst giyimi hava durumuna göre seç
  ClothingItemModel? _selectBestUpperForWeather(List<ClothingItemModel> uppers, WeatherModel weather) {
    if (uppers.isEmpty) return null;
    
    // Hava durumuna göre ağırlıklandırma
    final scoredItems = uppers.map((item) {
      double score = 0;
      
      // Mevsime uygunluğu kontrol et
      final seasons = _getSuitableSeasonsForWeather(weather);
      if (item.seasons.any((s) => seasons.contains(s))) {
        score += 3;
      }
      
      // Sıcaklık için uygun kıyafet tipini kontrol et
      final temperature = weather.temperature;
      if (temperature < 10) {
        if (item.type == ClothingType.sweater) score += 4;
        else if (item.type == ClothingType.shirt) score += 1;
        else if (item.type == ClothingType.tShirt) score -= 2;
      } else if (temperature < 20) {
        if (item.type == ClothingType.shirt) score += 3;
        else if (item.type == ClothingType.sweater) score += 1;
        else if (item.type == ClothingType.tShirt) score += 1;
      } else {
        if (item.type == ClothingType.tShirt) score += 4;
        else if (item.type == ClothingType.shirt) score += 2;
        else if (item.type == ClothingType.sweater) score -= 2;
      }
      
      return MapEntry(item, score);
    }).toList();
    
    // En yüksek skora sahip üst giyimi seç
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.isNotEmpty ? scoredItems.first.key : null;
  }
  
  // Üst giyime uygun alt giyimi seç
  ClothingItemModel? _selectMatchingLower(
    ClothingItemModel upper, 
    List<ClothingItemModel> lowers,
    String? skinTone
  ) {
    if (lowers.isEmpty) return null;
    
    final scoredItems = lowers.map((item) {
      double score = 0;
      
      // Renk uyumunu kontrol et
      score += _calculateColorMatchScore(upper.colors, item.colors);
      
      // Cilt tonuna uygunluğu kontrol et
      if (skinTone != null) {
        final suitableColors = _colorAnalysisService.getColorsForSkinTone(skinTone);
        for (final color in item.colors) {
          try {
            final itemColor = Color(int.parse(color.replaceFirst('#', '0xFF')));
            for (final suitable in suitableColors) {
              if (_calculateColorDistance(itemColor, suitable) < 100) {
                score += 2;
                break;
              }
            }
          } catch (e) {
            // Geçersiz renk formatı
          }
        }
      }
      
      return MapEntry(item, score);
    }).toList();
    
    // En yüksek skora sahip alt giyimi seç
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.isNotEmpty ? scoredItems.first.key : null;
  }
  
  // Kombine uygun dış giyim seç
  ClothingItemModel? _selectMatchingOuterwear(
    List<ClothingItemModel> currentOutfit,
    List<ClothingItemModel> outwears
  ) {
    if (outwears.isEmpty || currentOutfit.isEmpty) return null;
    
    final scoredItems = outwears.map((item) {
      double score = 0;
      
      // Mevcut kıyafetlerle renk uyumunu kontrol et
      for (final clothingItem in currentOutfit) {
        score += _calculateColorMatchScore(item.colors, clothingItem.colors);
      }
      
      // Ortalama skoru hesapla
      score = score / currentOutfit.length;
      
      return MapEntry(item, score);
    }).toList();
    
    // En yüksek skora sahip dış giyimi seç
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.isNotEmpty ? scoredItems.first.key : null;
  }
  
  // Kombine uygun ayakkabı seç
  ClothingItemModel? _selectMatchingShoes(
    List<ClothingItemModel> currentOutfit,
    List<ClothingItemModel> shoes
  ) {
    if (shoes.isEmpty || currentOutfit.isEmpty) return null;
    
    final scoredItems = shoes.map((item) {
      double score = 0;
      
      // Mevcut kıyafetlerle renk uyumunu kontrol et
      for (final clothingItem in currentOutfit) {
        score += _calculateColorMatchScore(item.colors, clothingItem.colors);
      }
      
      // Ortalama skoru hesapla
      score = score / currentOutfit.length;
      
      return MapEntry(item, score);
    }).toList();
    
    // En yüksek skora sahip ayakkabıyı seç
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.isNotEmpty ? scoredItems.first.key : null;
  }
  
  // İki renk listesi arasındaki uyum skorunu hesapla
  double _calculateColorMatchScore(List<String> colors1, List<String> colors2) {
    if (colors1.isEmpty || colors2.isEmpty) return 0;
    
    double totalScore = 0;
    int comparisons = 0;
    
    for (final c1 in colors1) {
      for (final c2 in colors2) {
        try {
          final color1 = Color(int.parse(c1.replaceFirst('#', '0xFF')));
          final color2 = Color(int.parse(c2.replaceFirst('#', '0xFF')));
          
          final double distance = _calculateColorDistance(color1, color2);
          
          // Renk mesafesini skora dönüştür (daha yakın = daha yüksek skor)
          // 0-100 arası mesafe yüksek uyum, 100-200 orta uyum, 200+ düşük uyum
          if (distance < 100) {
            totalScore += 5;
          } else if (distance < 200) {
            totalScore += 3;
          } else {
            totalScore += 1;
          }
          
          comparisons++;
        } catch (e) {
          // Geçersiz renk formatı
        }
      }
    }
    
    return comparisons > 0 ? totalScore / comparisons : 0;
  }
  
  // İki renk arasındaki mesafeyi hesapla (Euclidean distance)
  double _calculateColorDistance(Color c1, Color c2) {
    final double rDiff = (c1.red - c2.red).abs().toDouble();
    final double gDiff = (c1.green - c2.green).abs().toDouble();
    final double bDiff = (c1.blue - c2.blue).abs().toDouble();
    
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }
  
  // Bir kıyafet türünün üst giyim olup olmadığını kontrol et
  bool _isUpperClothing(ClothingType type) {
    return [
      ClothingType.tShirt,
      ClothingType.shirt,
      ClothingType.blouse,
      ClothingType.sweater,
    ].contains(type);
  }
  
  // Bir kıyafet türünün alt giyim olup olmadığını kontrol et
  bool _isLowerClothing(ClothingType type) {
    return [
      ClothingType.jeans,
      ClothingType.pants,
      ClothingType.shorts,
      ClothingType.skirt,
      ClothingType.dress, // Elbise hem üst hem alt giyim sayılabilir
    ].contains(type);
  }
  
  // Bir kıyafet türünün dış giyim olup olmadığını kontrol et
  bool _isOuterwear(ClothingType type) {
    return [
      ClothingType.jacket,
      ClothingType.coat,
    ].contains(type);
  }
  
  // Hava durumuna göre dış giyim gerekip gerekmediğini kontrol et
  bool _needsOuterwear(WeatherModel weather) {
    // Dış giyim gerektiren hava koşulları
    if ([
      WeatherCondition.rainy,
      WeatherCondition.snowy,
      WeatherCondition.stormy,
      WeatherCondition.windy,
      WeatherCondition.foggy,
      WeatherCondition.cold,
    ].contains(weather.condition)) {
      return true;
    }
    
    // Sıcaklık kontrolü
    return weather.temperature < 15.0; // 15 derecenin altında dış giyim gerekir
  }
  
  // Hava durumuna göre uygun kıyafet tiplerini belirle
  List<ClothingType> _getSuitableClothingTypes(WeatherModel weather) {
    final condition = weather.condition;
    final temperature = weather.temperature;
    
    List<ClothingType> types = [];
    
    // Temel üst giyim
    if (temperature < 10) {
      types.add(ClothingType.sweater);
    } else if (temperature < 20) {
      types.addAll([ClothingType.shirt, ClothingType.blouse, ClothingType.sweater]);
    } else {
      types.addAll([ClothingType.tShirt, ClothingType.shirt, ClothingType.blouse]);
    }
    
    // Temel alt giyim
    if (temperature < 15) {
      types.addAll([ClothingType.jeans, ClothingType.pants]);
    } else if (temperature < 25) {
      types.addAll([ClothingType.jeans, ClothingType.pants, ClothingType.skirt]);
    } else {
      types.addAll([ClothingType.shorts, ClothingType.skirt]);
    }
    
    // Elbise - sıcak havada tercih edilir
    if (temperature > 18) {
      types.add(ClothingType.dress);
    }
    
    // Dış giyim
    if (temperature < 5) {
      types.add(ClothingType.coat);
    } else if (temperature < 15) {
      types.addAll([ClothingType.jacket, ClothingType.coat]);
    } else if (temperature < 20 && (condition == WeatherCondition.windy || condition == WeatherCondition.rainy)) {
      types.add(ClothingType.jacket);
    }
    
    // Ayakkabı
    if (condition == WeatherCondition.rainy || condition == WeatherCondition.snowy) {
      types.add(ClothingType.boots);
    } else {
      types.add(ClothingType.shoes);
    }
    
    // Aksesuar (şapka, atkı vb.)
    if (temperature < 10 || condition == WeatherCondition.snowy) {
      types.addAll([ClothingType.hat, ClothingType.scarf]);
    }
    
    types.add(ClothingType.accessory); // Aksesuarlar her durumda olabilir
    
    return types;
  }
  
  // Hava durumuna göre uygun mevsimleri belirle
  List<Season> _getSuitableSeasonsForWeather(WeatherModel weather) {
    final temperature = weather.temperature;
    final condition = weather.condition;
    
    // Sıcaklığa göre mevsim tahmini
    if (temperature <= 5) {
      return [Season.winter];
    } else if (temperature <= 15) {
      return [Season.winter, Season.fall, Season.spring];
    } else if (temperature <= 25) {
      return [Season.fall, Season.spring, Season.summer];
    } else {
      return [Season.summer];
    }
  }
} 