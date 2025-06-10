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

// Şehir seçimi state provider
final selectedCityProvider = StateProvider<String>((ref) => 'Istanbul');

// Favori şehirler provider
final favoriteCitiesProvider = StateProvider<List<String>>((ref) => [
  'Istanbul',
  'Ankara',
  'Izmir',
  'Bursa',
  'Adana',
  'Antalya',
  'Gaziantep',
  'Konya',
  'Mersin',
  'Kayseri'
]);

// Hava durumu durum sınıfı
class WeatherState {
  final WeatherModel? currentWeather;
  final List<WeatherModel>? forecast;
  final String? error;
  final bool isLoading;
  final bool locationFailed;
  final String currentCity;

  const WeatherState({
    this.currentWeather,
    this.forecast,
    this.error,
    this.isLoading = false,
    this.locationFailed = false,
    this.currentCity = 'Istanbul',
  });

  WeatherState copyWith({
    WeatherModel? currentWeather,
    List<WeatherModel>? forecast,
    String? error,
    bool? isLoading,
    bool? locationFailed,
    String? currentCity,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      locationFailed: locationFailed ?? this.locationFailed,
      currentCity: currentCity ?? this.currentCity,
    );
  }
}

class WeatherStateNotifier extends StateNotifier<WeatherState> {
  final ApiService _apiService;
  final LocationService _locationService;

  WeatherStateNotifier(this._apiService, this._locationService) : super(const WeatherState()) {
    // Başlangıçta konum bazlı hava durumunu al
    _initializeWeather();
  }

  Future<void> _initializeWeather() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🌍 WeatherProvider: Başlatılıyor...');
      debugPrint('🌍 WeatherProvider: Konum bilgisi alınmaya çalışılıyor...');
      
      final position = await _locationService.getCurrentLocation();
      
      if (position != null && position.latitude != null && position.longitude != null) {
        debugPrint('✅ WeatherProvider: Konum başarıyla alındı: ${position.latitude}, ${position.longitude}');
        
        try {
          final weather = await _apiService.getWeatherByLocation(
            position.latitude!,
            position.longitude!,
          );
          final forecast = await _apiService.get5DayForecast(weather.location);
          
          state = state.copyWith(
            currentWeather: weather,
            forecast: forecast,
            isLoading: false,
            locationFailed: false,
            currentCity: weather.location,
          );
          
          debugPrint('✅ WeatherProvider: Hava durumu konum bazlı başarıyla alındı: ${weather.location}');
        } catch (e) {
          debugPrint('❌ WeatherProvider: Konum bazlı hava durumu API hatası: $e');
          debugPrint('⚠️ WeatherProvider: Varsayılan şehre geçiliyor...');
          await _fallbackToDefaultCity();
        }
      } else {
        debugPrint('⚠️ WeatherProvider: Konum bilgisi null veya geçersiz, varsayılan şehre geçiliyor: Istanbul');
        await _fallbackToDefaultCity();
      }
    } catch (e) {
      debugPrint('❌ WeatherProvider: Konum alma sırasında genel hata: $e');
      debugPrint('⚠️ WeatherProvider: Varsayılan şehre geçiliyor...');
      await _fallbackToDefaultCity();
    }
  }

  Future<void> _fallbackToDefaultCity() async {
    try {
      debugPrint('🏙️ WeatherProvider: Varsayılan şehir (Istanbul) için hava durumu alınıyor...');
      const defaultCity = 'Istanbul';
      
      final weather = await _apiService.getCurrentWeather(defaultCity);
      final forecast = await _apiService.get5DayForecast(defaultCity);
      
      state = state.copyWith(
        currentWeather: weather,
        forecast: forecast,
        isLoading: false,
        locationFailed: true,
        currentCity: defaultCity,
        error: null,
      );
      
      debugPrint('✅ WeatherProvider: Varsayılan şehir hava durumu başarıyla alındı - ${weather.location}');
    } catch (e) {
      debugPrint('❌ WeatherProvider: Varsayılan şehir hava durumu hatası: $e');
      state = state.copyWith(
        error: 'Hava durumu alınamadı. Lütfen internet bağlantınızı kontrol edin.',
        isLoading: false,
        locationFailed: true,
      );
    }
  }

  Future<void> getWeatherByCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🌍 Manuel konum güncellenmesi istendi...');
      final position = await _locationService.getCurrentLocation();
      
      if (position != null && position.latitude != null && position.longitude != null) {
        final weather = await _apiService.getWeatherByLocation(
          position.latitude!,
          position.longitude!,
        );
        final forecast = await _apiService.get5DayForecast(weather.location);
        
        state = state.copyWith(
          currentWeather: weather,
          forecast: forecast,
          isLoading: false,
          locationFailed: false,
          currentCity: weather.location,
        );
        
        debugPrint('✅ Manuel konum güncellemesi başarılı: ${weather.location}');
      } else {
        state = state.copyWith(
          error: 'Konum bilgisi alınamadı. Konum servislerinin açık olduğundan emin olun.',
          isLoading: false,
          locationFailed: true,
        );
        debugPrint('❌ Manuel konum güncellemesi başarısız');
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Konum alınırken hata oluştu: ${e.toString()}',
        isLoading: false,
        locationFailed: true,
      );
      debugPrint('❌ Manuel konum güncellemesi hatası: $e');
    }
  }

  Future<void> getWeatherByCity(String city) async {
    if (city.trim().isEmpty) {
      debugPrint('⚠️ Boş şehir adı girişi');
      return;
    }
    
    final trimmedCity = city.trim();
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🏙️ Şehir bazlı hava durumu alınıyor: $trimmedCity');
      
      final weather = await _apiService.getCurrentWeather(trimmedCity);
      final forecast = await _apiService.get5DayForecast(trimmedCity);
      
      state = state.copyWith(
        currentWeather: weather,
        forecast: forecast,
        isLoading: false,
        locationFailed: false,
        currentCity: weather.location,
      );
      
      debugPrint('✅ Şehir bazlı hava durumu başarıyla alındı: ${weather.location}');
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Şehir bulunamadı')) {
        errorMessage = 'Şehir bulunamadı: $trimmedCity. Lütfen doğru şehir adını girin.';
      } else if (e.toString().contains('zaman aşımı')) {
        errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
      } else {
        errorMessage = 'Hava durumu alınırken hata oluştu. Lütfen tekrar deneyin.';
      }
      
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      debugPrint('❌ Şehir bazlı hava durumu hatası: $e');
    }
  }

  Future<void> refreshWeather() async {
    debugPrint('🔄 Hava durumu yenileniyor...');
    
    if (state.currentWeather != null) {
      await getWeatherByCity(state.currentCity);
    } else if (!state.locationFailed) {
      await getWeatherByCurrentLocation();
    } else {
      await _fallbackToDefaultCity();
    }
  }

  // Şehir önerilerini getir
  List<String> getCitySuggestions(String query) {
    if (query.trim().isEmpty) return [];
    
    final turkishCities = [
      'Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Adana', 'Antalya',
      'Gaziantep', 'Konya', 'Mersin', 'Kayseri', 'Eskisehir', 'Diyarbakir',
      'Samsun', 'Denizli', 'Sakarya', 'Trabzon', 'Van', 'Malatya',
      'Erzurum', 'Batman', 'Elazig', 'Erzincan', 'Sivas', 'Tokat',
      'Aksaray', 'Afyon', 'Isparta', 'Kastamonu', 'Kirklareli', 'Edirne'
    ];
    
    final lowerQuery = query.toLowerCase();
    
    return turkishCities
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  }
} 