# 👔 Kombin Önerisi Modülü

## 📝 Genel Bakış

Kombin önerisi modülü, makine öğrenmesi ve renk teorisi kullanarak kullanıcılara hava durumuna uygun kıyafet kombinleri önerir. Sistem, kullanıcının stil tercihlerini, hava koşullarını ve renk uyumunu dikkate alır.

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- TensorFlow Lite (stil analizi)
- OpenCV (renk uyumu)
- Firebase ML Kit
- Custom ML modeli

### Öneri Sistemi Mimarisi

#### 1. Kombin Modeli
```dart
// lib/features/outfit/models/outfit.dart
class Outfit {
  final String id;
  final String userId;
  final List<ClothingItem> items;
  final WeatherCondition suitableWeather;
  final List<Season> suitableSeasons;
  final double styleScore;
  final double weatherScore;
  final double colorScore;

  double get totalScore => 
    (styleScore * 0.4) + (weatherScore * 0.4) + (colorScore * 0.2);
}
```

### Öneri Algoritması

#### 1. Hava Durumu Uygunluğu
```dart
// lib/features/outfit/services/weather_compatibility.dart
class WeatherCompatibilityService {
  double calculateWeatherScore(
    Outfit outfit, 
    WeatherData weather,
  ) {
    double score = 0.0;
    
    // Sıcaklık uygunluğu
    score += _calculateTemperatureScore(
      outfit.items,
      weather.temperature,
    );
    
    // Yağış durumu
    if (weather.isRainy && !outfit.hasWaterproofItem) {
      score -= 0.3;
    }
    
    // Rüzgar durumu
    if (weather.windSpeed > 20 && !outfit.hasWindproofItem) {
      score -= 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }
}
```

#### 2. Renk Uyumu Analizi
```dart
// lib/features/outfit/services/color_harmony.dart
class ColorHarmonyService {
  double calculateColorScore(List<ClothingItem> items) {
    final colors = items.expand((item) => item.colors).toList();
    
    // Renk çarkı analizi
    double harmonyScore = _analyzeColorWheel(colors);
    
    // Kontrast değerlendirmesi
    double contrastScore = _calculateContrast(colors);
    
    // Sezon uyumu
    double seasonScore = _analyzeSeasonalColors(colors);
    
    return (harmonyScore * 0.4 + 
            contrastScore * 0.3 + 
            seasonScore * 0.3)
        .clamp(0.0, 1.0);
  }
}
```

#### 3. Stil Analizi
```dart
// lib/features/outfit/services/style_analyzer.dart
class StyleAnalyzer {
  final Interpreter _styleModel;
  
  Future<Map<String, double>> analyzeStyle(List<ClothingItem> items) async {
    // Stil özelliklerini çıkar
    final features = await _extractStyleFeatures(items);
    
    // ML modeli ile analiz
    final output = await _styleModel.run(features);
    
    // Stil kategorilerine ayır
    return {
      'casual': output[0],
      'formal': output[1],
      'sporty': output[2],
      'elegant': output[3],
    };
  }
}
```

## 📱 Ekran Görüntüleri ve Akış

### Kombin Önerisi Ekranı
<img src="../assets/screenshots/outfit_recommendation.png" width="300">

1. Hava durumu özeti
2. Önerilen kombinler
3. Uygunluk skorları
4. Detaylı bilgiler

### Kombin Detay Ekranı
<img src="../assets/screenshots/outfit_detail.png" width="300">

1. Kıyafet parçaları
2. Renk uyumu analizi
3. Hava durumu uygunluğu
4. Stil değerlendirmesi

## 🧠 Öneri Motoru

```dart
// lib/features/outfit/services/recommendation_engine.dart
class OutfitRecommendationEngine {
  final WeatherCompatibilityService _weatherService;
  final ColorHarmonyService _colorService;
  final StyleAnalyzer _styleAnalyzer;
  
  Future<List<Outfit>> generateRecommendations({
    required WeatherData weather,
    required UserPreferences preferences,
    required List<ClothingItem> wardrobe,
    int limit = 5,
  }) async {
    // 1. Hava durumuna göre uygun kıyafetleri filtrele
    final weatherSuitableItems = _filterByWeather(wardrobe, weather);
    
    // 2. Olası kombinasyonları oluştur
    final possibleOutfits = _generateCombinations(weatherSuitableItems);
    
    // 3. Her kombinasyon için skor hesapla
    final scoredOutfits = await Future.wait(
      possibleOutfits.map((outfit) async {
        final weatherScore = _weatherService.calculateWeatherScore(
          outfit, 
          weather,
        );
        
        final colorScore = _colorService.calculateColorScore(
          outfit.items,
        );
        
        final styleScores = await _styleAnalyzer.analyzeStyle(
          outfit.items,
        );
        
        final styleScore = _calculateStyleCompatibility(
          styleScores,
          preferences.preferredStyles,
        );
        
        return outfit.copyWith(
          weatherScore: weatherScore,
          colorScore: colorScore,
          styleScore: styleScore,
        );
      }),
    );
    
    // 4. En iyi kombinleri seç
    return scoredOutfits
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore))
      ..take(limit)
      .toList();
  }
}
```

## 🔄 State Management

```dart
// lib/features/outfit/providers/outfit_provider.dart
final outfitRecommendationsProvider = StateNotifierProvider<
    OutfitRecommendationsNotifier,
    AsyncValue<List<Outfit>>>((ref) {
  return OutfitRecommendationsNotifier(
    ref.read(recommendationEngineProvider),
    ref.read(weatherProvider),
    ref.read(wardrobeProvider),
  );
});

class OutfitRecommendationsNotifier extends StateNotifier<AsyncValue<List<Outfit>>> {
  final OutfitRecommendationEngine _engine;
  final WeatherState _weather;
  final WardrobeState _wardrobe;
  
  Future<void> generateRecommendations() async {
    state = const AsyncValue.loading();
    try {
      final recommendations = await _engine.generateRecommendations(
        weather: _weather.currentWeather,
        preferences: await _loadUserPreferences(),
        wardrobe: _wardrobe.clothes,
      );
      state = AsyncValue.data(recommendations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

## 🚀 Kullanım Örneği

```dart
class OutfitRecommendationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsState = ref.watch(outfitRecommendationsProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Kombin Önerileri')),
      body: recommendationsState.when(
        data: (outfits) => ListView.builder(
          itemCount: outfits.length,
          itemBuilder: (context, index) {
            final outfit = outfits[index];
            return OutfitCard(
              outfit: outfit,
              onTap: () => _showOutfitDetails(context, outfit),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(message: error.toString()),
      ),
    );
  }
}
``` 