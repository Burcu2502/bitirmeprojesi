# 🌤️ Hava Durumu Modülü

## 📝 Genel Bakış

Hava durumu modülü, OpenWeatherMap API'sini kullanarak gerçek zamanlı hava durumu verilerini alır ve kullanıcıya sunar. Bu veriler, kombin önerileri için temel girdi olarak kullanılır.

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- OpenWeatherMap API
- Geolocator (konum servisleri)
- HTTP paket
- JSON serialization

### API Entegrasyonu

#### 1. Hava Durumu Servisi
```dart
// lib/features/weather/services/weather_service.dart
class WeatherService {
  final String apiKey = 'YOUR_API_KEY';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    final url = '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw WeatherException('Hava durumu verileri alınamadı');
    }
  }

  Future<List<WeatherData>> getForecast(double lat, double lon) async {
    final url = '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['list'] as List)
          .map((e) => WeatherData.fromJson(e))
          .toList();
    } else {
      throw WeatherException('Tahmin verileri alınamadı');
    }
  }
}
```

#### 2. Veri Modeli
```dart
// lib/features/weather/models/weather_data.dart
class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime timestamp;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}
```

## 📱 Ekran Görüntüleri ve Akış

### Ana Hava Durumu Ekranı
<img src="../assets/screenshots/weather_main.png" width="300">

1. Kullanıcının konumu alınır
2. Güncel hava durumu verileri çekilir
3. 5 günlük tahmin gösterilir
4. Sıcaklık, nem, rüzgar hızı gibi detaylar sunulur

### Hava Durumu Widget'ı
<img src="../assets/screenshots/weather_widget.png" width="300">

1. Anlık sıcaklık gösterimi
2. Hava durumu ikonu
3. Hissedilen sıcaklık
4. Kısa tahmin bilgisi

## 🔄 State Management

```dart
// lib/features/weather/providers/weather_provider.dart
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ref.read(weatherServiceProvider));
});

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;
  
  Future<void> fetchWeather(double lat, double lon) async {
    state = state.copyWith(isLoading: true);
    try {
      final weather = await _weatherService.getCurrentWeather(lat, lon);
      final forecast = await _weatherService.getForecast(lat, lon);
      state = state.copyWith(
        currentWeather: weather,
        forecast: forecast,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
```

## 🎯 Kombin Önerileri için Hava Durumu Analizi

```dart
// lib/features/weather/services/weather_analyzer.dart
class WeatherAnalyzer {
  WeatherSuitability analyzeSuitability(WeatherData weather) {
    return WeatherSuitability(
      temperature: _analyzeTemperature(weather.temperature),
      precipitation: _analyzePrecipitation(weather.description),
      windSpeed: _analyzeWindSpeed(weather.windSpeed),
    );
  }

  ClothingRecommendation getRecommendation(WeatherSuitability suitability) {
    return ClothingRecommendation(
      layers: _calculateLayers(suitability.temperature),
      waterproof: suitability.precipitation > 0.5,
      windproof: suitability.windSpeed > 20,
    );
  }
}
```

## 🔄 Veri Akışı

1. **Konum Alımı**
   ```dart
   final position = await Geolocator.getCurrentPosition();
   ```

2. **Hava Durumu Verisi Çekme**
   ```dart
   final weather = await weatherService.getCurrentWeather(
     position.latitude,
     position.longitude,
   );
   ```

3. **Veri İşleme ve Analiz**
   ```dart
   final suitability = weatherAnalyzer.analyzeSuitability(weather);
   final recommendation = weatherAnalyzer.getRecommendation(suitability);
   ```

4. **UI Güncelleme**
   ```dart
   ref.read(weatherProvider.notifier).updateWeather(weather);
   ```

## 🚀 Kullanım Örneği

```dart
class WeatherScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherProvider);
    
    return Scaffold(
      body: weatherState.when(
        data: (weather) => WeatherDisplay(weather: weather),
        loading: () => CircularProgressIndicator(),
        error: (error) => ErrorDisplay(message: error),
      ),
    );
  }
}
``` 