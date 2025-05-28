import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/api_service.dart';
import 'location_provider.dart';
import '../../../../core/models/clothing_item_model.dart';

// ApiService provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Hava durumu state provider
final weatherStateProvider = StateNotifierProvider<WeatherStateNotifier, WeatherState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return WeatherStateNotifier(apiService, locationService);
});

// Hava durumu durum sınıfı
class WeatherState {
  final WeatherModel? currentWeather;
  final List<WeatherModel>? forecast;
  final String? error;
  final bool isLoading;

  const WeatherState({
    this.currentWeather,
    this.forecast,
    this.error,
    this.isLoading = false,
  });

  WeatherState copyWith({
    WeatherModel? currentWeather,
    List<WeatherModel>? forecast,
    String? error,
    bool? isLoading,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WeatherStateNotifier extends StateNotifier<WeatherState> {
  final ApiService _apiService;
  final LocationService _locationService;

  WeatherStateNotifier(this._apiService, this._locationService) : super(const WeatherState()) {
    // Başlangıçta konum bazlı hava durumunu al
    getWeatherByCurrentLocation();
  }

  Future<void> getWeatherByCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final weather = await _apiService.getWeatherByLocation(
          position.latitude ?? 0,
          position.longitude ?? 0,
        );
        final forecast = await _apiService.get5DayForecast(weather.location);
        
        state = state.copyWith(
          currentWeather: weather,
          forecast: forecast,
          isLoading: false,
        );
      } else {
        // Konum alınamazsa varsayılan şehir
        await getWeatherByCity('Istanbul');
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Hava durumu alınırken hata oluştu: $e',
        isLoading: false,
      );
      debugPrint('Hava durumu alınırken hata: $e');
    }
  }

  Future<void> getWeatherByCity(String city) async {
    if (city.isEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _apiService.getCurrentWeather(city);
      final forecast = await _apiService.get5DayForecast(city);
      
      state = state.copyWith(
        currentWeather: weather,
        forecast: forecast,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Hava durumu alınırken hata oluştu: $e',
        isLoading: false,
      );
      debugPrint('Hava durumu alınırken hata: $e');
    }
  }

  Future<void> refreshWeather() async {
    if (state.currentWeather != null) {
      await getWeatherByCity(state.currentWeather!.location);
    } else {
      await getWeatherByCurrentLocation();
    }
  }
} 