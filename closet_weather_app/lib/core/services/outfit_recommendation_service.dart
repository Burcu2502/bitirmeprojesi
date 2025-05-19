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
    // Kıyafet kontrolü - eğer hiç kıyafet yoksa boş liste döndür
    if (availableItems.isEmpty) {
      return [];
    }

    // Hava durumuna uygun kıyafet tiplerini belirle
    final List<ClothingType> suitableTypes = _getSuitableClothingTypes(weather);
    
    // Hava durumuna uygun mevsimleri belirle (Tüm Sezonlar dahil)
    final List<Season> suitableSeasons = _getSuitableSeasonsForWeather(weather);
    // Her zaman tüm sezonları kabul et
    if (!suitableSeasons.contains(Season.all)) {
      suitableSeasons.add(Season.all);
    }
    
    // DEBUG: Mevsimler hakkında log
    debugPrint("🌍 Hava durumuna uygun mevsimler: $suitableSeasons");
    
    // Filtrele ama mevsim uyumsuzluğunda bile en az bir kıyafet seç
    
    // Uygun üst giyim kıyafetlerini seç
    var uppers = availableItems.where((item) => 
      suitableTypes.contains(item.type) &&
      _isUpperClothing(item.type) &&
      item.seasons.any((season) => suitableSeasons.contains(season))
    ).toList();
    
    // Eğer uygun üst giyim yoksa, mevsim filtresini kaldır
    if (uppers.isEmpty) {
      uppers = availableItems.where((item) => 
        _isUpperClothing(item.type)
      ).toList();
    }
    
    // Uygun alt giyim kıyafetlerini seç
    var lowers = availableItems.where((item) => 
      suitableTypes.contains(item.type) &&
      _isLowerClothing(item.type) &&
      item.seasons.any((season) => suitableSeasons.contains(season))
    ).toList();
    
    // Eğer uygun alt giyim yoksa, mevsim filtresini kaldır
    if (lowers.isEmpty) {
      lowers = availableItems.where((item) => 
        _isLowerClothing(item.type)
      ).toList();
    }
    
    // Uygun ayakkabıları seç
    final shoes = availableItems.where((item) => 
      (item.type == ClothingType.shoes || item.type == ClothingType.boots)
    ).toList();
    
    // Uygun dış giyimleri seç
    final outwear = availableItems.where((item) => 
      _isOuterwear(item.type)
    ).toList();
    
    // Bulunan kıyafetleri logla
    debugPrint("👚 Bulunan üst giyim sayısı: ${uppers.length}");
    debugPrint("👖 Bulunan alt giyim sayısı: ${lowers.length}");
    
    // Eğer yeterli kıyafet yoksa boş liste döndür
    if (uppers.isEmpty || lowers.isEmpty) {
      debugPrint("⚠️ Yeterli kıyafet bulunamadı, kombin oluşturulamadı");
      return [];
    }
    
    // Renk uyumuna göre sırala
    List<ClothingItemModel> recommendation = [];
    
    // Üst giyim seç
    final upper = uppers.isNotEmpty ? uppers.first : null;
    if (upper != null) {
      recommendation.add(upper);
    }
    
    // Alt giyim seç
    final lower = lowers.isNotEmpty ? lowers.first : null;
    if (lower != null) {
      recommendation.add(lower);
    }
    
    // Hava durumuna göre dış giyim ekle
    if (outwear.isNotEmpty && _needsOuterwear(weather)) {
      final outerwearItem = outwear.first;
      recommendation.add(outerwearItem);
    }
    
    // Ayakkabı ekle
    if (shoes.isNotEmpty) {
      final shoe = shoes.first;
      recommendation.add(shoe);
    }
    
    return recommendation;
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
  
  // Hava durumuna göre uygun kıyafet tiplerini belirle
  List<ClothingType> _getSuitableClothingTypes(WeatherModel weather) {
    final temperature = weather.temperature;
    final condition = weather.condition;
    
    List<ClothingType> types = [];
    
    // Sıcaklığa göre üst giyim
    if (temperature < 5) {
      types.addAll([ClothingType.sweater]);
    } else if (temperature < 15) {
      types.addAll([ClothingType.sweater, ClothingType.shirt]);
    } else if (temperature < 25) {
      types.addAll([ClothingType.shirt, ClothingType.tShirt]);
    } else {
      types.addAll([ClothingType.tShirt, ClothingType.shirt]);
    }
    
    // Sıcaklığa göre alt giyim
    if (temperature < 10) {
      types.addAll([ClothingType.pants, ClothingType.jeans]);
    } else if (temperature < 20) {
      types.addAll([ClothingType.pants, ClothingType.jeans, ClothingType.skirt]);
    } else {
      types.addAll([ClothingType.shorts, ClothingType.skirt, ClothingType.pants]);
    }
    
    // Dış giyim
    if (temperature < 5) {
      types.addAll([ClothingType.coat]);
    } else if (temperature < 15) {
      types.addAll([ClothingType.jacket, ClothingType.coat]);
    } else if (temperature < 20 && 
              (condition == WeatherCondition.rainy || 
               condition == WeatherCondition.cloudy)) {
      types.add(ClothingType.jacket);
    }
    
    // Ayakkabı
    if (condition == WeatherCondition.rainy || 
        condition == WeatherCondition.snowy ||
        temperature < 5) {
      types.add(ClothingType.boots);
    } else {
      types.add(ClothingType.shoes);
    }
    
    // Aksesuar
    if (temperature < 10) {
      types.addAll([ClothingType.scarf, ClothingType.hat]);
    }
    
    return types;
  }
  
  // Hava durumuna göre uygun mevsimleri belirle
  List<Season> _getSuitableSeasonsForWeather(WeatherModel weather) {
    final temperature = weather.temperature;
    final date = weather.timestamp;
    final month = date.month;
    
    // Mevsimi belirle
    List<Season> seasons = [Season.all];
    
    // Astronomik mevsimlere göre
    if (month >= 3 && month <= 5) {
      seasons.add(Season.spring);
    } else if (month >= 6 && month <= 8) {
      seasons.add(Season.summer);
    } else if (month >= 9 && month <= 11) {
      seasons.add(Season.fall);
    } else {
      seasons.add(Season.winter);
    }
    
    // Sıcaklığa göre düzeltme
    if (temperature < 5) {
      if (!seasons.contains(Season.winter)) seasons.add(Season.winter);
    } else if (temperature > 25) {
      if (!seasons.contains(Season.summer)) seasons.add(Season.summer);
    }
    
    return seasons;
  }
  
  // Dış giyim gerekip gerekmediğini belirle
  bool _needsOuterwear(WeatherModel weather) {
    final temperature = weather.temperature;
    final condition = weather.condition;
    
    if (temperature < 15) return true;
    if (temperature < 20 && 
       (condition == WeatherCondition.rainy || 
        condition == WeatherCondition.cloudy ||
        condition == WeatherCondition.foggy)) {
      return true;
    }
    
    return false;
  }
  
  // Kıyafet tipinin üst giyim olup olmadığını kontrol et
  bool _isUpperClothing(ClothingType type) {
    return type == ClothingType.tShirt ||
           type == ClothingType.shirt ||
           type == ClothingType.blouse ||
           type == ClothingType.sweater;
  }
  
  // Kıyafet tipinin alt giyim olup olmadığını kontrol et
  bool _isLowerClothing(ClothingType type) {
    return type == ClothingType.pants ||
           type == ClothingType.jeans ||
           type == ClothingType.shorts ||
           type == ClothingType.skirt;
  }
  
  // Kıyafet tipinin dış giyim olup olmadığını kontrol et
  bool _isOuterwear(ClothingType type) {
    return type == ClothingType.jacket ||
           type == ClothingType.coat;
  }
} 