import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/api_service.dart';
import 'location_provider.dart'; // Yeni sadeleştirilmiş location provider

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
  return WeatherStateNotifier(ref);
});

// Hava durumu state'i
class WeatherState {
  final WeatherModel? currentWeather;
  final List<WeatherModel>? forecast;
  final bool isLoading;
  final String? error;

  WeatherState({
    this.currentWeather,
    this.forecast,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherModel? currentWeather,
    List<WeatherModel>? forecast,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Hava durumu state notifier
class WeatherStateNotifier extends StateNotifier<WeatherState> {
  final Ref _ref;
  
  WeatherStateNotifier(this._ref) : super(WeatherState(isLoading: true)) {
    // İlk başta verileri yükle
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final weatherData = await _ref.read(currentWeatherProvider.future);
      final forecastData = await _ref.read(forecastProvider.future);
      
      state = state.copyWith(
        currentWeather: weatherData,
        forecast: forecastData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Hava durumu bilgileri alınamadı: $e',
      );
    }
  }

  Future<void> updateLocation(String location) async {
    _ref.read(currentLocationProvider.notifier).state = location;
    await fetchWeatherData();
  }
} 