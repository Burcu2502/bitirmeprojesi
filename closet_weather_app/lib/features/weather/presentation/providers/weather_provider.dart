import 'package:closet_weather_app/core/models/outfit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/api_service.dart';
import 'location_provider.dart'; // Yeni sadeleştirilmiş location provider
import '../../../../core/models/clothing_item_model.dart';

// ApiService provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Mevcut konum provider (sadece manuel girilen)
final currentLocationProvider = StateProvider<String>((ref) {
  return 'Istanbul'; // Varsayılan olarak İstanbul
});

// Mevcut hava durumu için provider - doğrudan şehir adı ile
final currentWeatherProvider = FutureProvider<WeatherModel>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final location = ref.watch(currentLocationProvider);
  return await apiService.getCurrentWeather(location);
});

// 5 günlük tahmin için provider
final forecastProvider = FutureProvider<List<WeatherModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final location = ref.watch(currentLocationProvider);
  
  return await apiService.get5DayForecast(location);
});

// Tüm hava durumu bilgilerini bir arada tutan provider
final weatherStateProvider = StateNotifierProvider<WeatherStateNotifier, WeatherState>((ref) {
  return WeatherStateNotifier();
});

// Hava durumu durum sınıfı
class WeatherState {
  final WeatherModel? currentWeather;
  final List<WeatherModel>? forecast;
  final String? error;
  final bool isLoading;
  final String? location;

  const WeatherState({
    this.currentWeather,
    this.forecast,
    this.error,
    this.isLoading = false,
    this.location,
  });

  // Başlangıç durumu
  factory WeatherState.initial() {
    return const WeatherState(
      isLoading: false,
    );
  }

  // Kopyalama yardımcı metodu
  WeatherState copyWith({
    WeatherModel? currentWeather,
    List<WeatherModel>? forecast,
    String? error,
    bool? isLoading,
    String? location,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      location: location ?? this.location,
    );
  }
}

// Hava durumu state notifier sınıfı
class WeatherStateNotifier extends StateNotifier<WeatherState> {
  WeatherStateNotifier() : super(WeatherState.initial()) {
    // Demo verilerle başlat
    _loadDemoData();
  }

  // Demo verileri yükle
  Future<void> _loadDemoData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Demo hava durumu verisi oluştur
      final demoWeather = WeatherModel.demo();
      
      // Demo 5 günlük tahmin verisi oluştur
      final demoForecast = _generateDemoForecast();
      
      state = state.copyWith(
        currentWeather: demoWeather,
        forecast: demoForecast,
        isLoading: false,
        location: demoWeather.location,
      );
      
      debugPrint('Demo hava durumu verileri yüklendi');
    } catch (e) {
      state = state.copyWith(
        error: 'Demo verileri yüklenirken hata oluştu: $e',
        isLoading: false,
      );
      debugPrint('Demo verileri yüklenirken hata: $e');
    }
  }

  // Demo 5 günlük tahmin verisi oluştur
  List<WeatherModel> _generateDemoForecast() {
    final now = DateTime.now();
    return [
      WeatherModel(
        location: 'İstanbul',
        timestamp: now.add(const Duration(days: 1)),
        temperature: 24.0,
        feelsLike: 26.0,
        humidity: 60,
        windSpeed: 10.0,
        condition: WeatherCondition.sunny,
        description: 'Güneşli',
        icon: '01d',
      ),
      WeatherModel(
        location: 'İstanbul',
        timestamp: now.add(const Duration(days: 2)),
        temperature: 22.0,
        feelsLike: 23.0,
        humidity: 65,
        windSpeed: 12.0,
        condition: WeatherCondition.partlyCloudy,
        description: 'Parçalı bulutlu',
        icon: '02d',
      ),
      WeatherModel(
        location: 'İstanbul',
        timestamp: now.add(const Duration(days: 3)),
        temperature: 19.0,
        feelsLike: 18.0,
        humidity: 70,
        windSpeed: 15.0,
        condition: WeatherCondition.rainy,
        description: 'Yağmurlu',
        icon: '10d',
      ),
      WeatherModel(
        location: 'İstanbul',
        timestamp: now.add(const Duration(days: 4)),
        temperature: 17.0,
        feelsLike: 16.0,
        humidity: 75,
        windSpeed: 20.0,
        condition: WeatherCondition.windy,
        description: 'Rüzgarlı',
        icon: '50d',
      ),
      WeatherModel(
        location: 'İstanbul',
        timestamp: now.add(const Duration(days: 5)),
        temperature: 21.0,
        feelsLike: 22.0,
        humidity: 65,
        windSpeed: 10.0,
        condition: WeatherCondition.sunny,
        description: 'Güneşli',
        icon: '01d',
      ),
    ];
  }

  // Hava durumu verilerini yenile
  Future<void> fetchWeatherData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Demo hava durumu verisi oluştur
      final demoWeather = WeatherModel.demo();
      
      // Demo 5 günlük tahmin verisi oluştur
      final demoForecast = _generateDemoForecast();
      
      state = state.copyWith(
        currentWeather: demoWeather,
        forecast: demoForecast,
        isLoading: false,
      );
      
      debugPrint('Hava durumu verileri güncellendi');
    } catch (e) {
      state = state.copyWith(
        error: 'Hava durumu verileri güncellenirken hata oluştu: $e',
        isLoading: false,
      );
      debugPrint('Hava durumu verileri güncellenirken hata: $e');
    }
  }

  // Konumu güncelle
  Future<void> updateLocation(String location) async {
    if (location.isEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null, location: location);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Demo hava durumu verisi oluştur - yeni konumla
      final updatedWeather = WeatherModel.demo().copyWith(
        location: location
      );
      
      // Demo 5 günlük tahmin verisi oluştur - yeni konumla
      final updatedForecast = _generateDemoForecast().map(
        (forecast) => forecast.copyWith(location: location)
      ).toList();
      
      state = state.copyWith(
        currentWeather: updatedWeather,
        forecast: updatedForecast,
        isLoading: false,
      );
      
      debugPrint('Konum güncellendi: $location');
    } catch (e) {
      state = state.copyWith(
        error: 'Konum güncellenirken hata oluştu: $e',
        isLoading: false,
      );
      debugPrint('Konum güncellenirken hata: $e');
    }
  }
} 