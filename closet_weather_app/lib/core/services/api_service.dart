import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/outfit_model.dart';
import 'package:flutter/material.dart';

class ApiService {
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String apiKey = '3a1234a522faa5171f59468129ed45dc';

  Future<WeatherModel> getCurrentWeather(String city) async {
    try {
      if (city.isEmpty) {
        throw Exception('Şehir adı boş olamaz');
      }

      debugPrint('🌍 Hava durumu isteği gönderiliyor: $city');
      
      final response = await http.get(
        Uri.parse('$baseUrl/weather?q=$city&units=metric&lang=tr&appid=$apiKey'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Bağlantı zaman aşımına uğradı'),
      );

      debugPrint('📡 API yanıtı alındı: ${response.statusCode}');
      debugPrint('📡 API yanıtı: ${response}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          throw Exception('API yanıtı boş');
        }
        
        // API yanıtını kontrol et
        if (!data.containsKey('main') || !data.containsKey('weather')) {
          throw Exception('Geçersiz API yanıtı: Eksik alanlar');
        }
        
        return _parseWeatherData(data);
      } else if (response.statusCode == 404) {
        throw Exception('Şehir bulunamadı: $city');
      } else {
        throw Exception('Hava durumu verileri alınamadı (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Hava durumu verisi alınırken hata: $e');
      rethrow;
    }
  }

  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    try {
      if (lat == 0 || lon == 0) {
        throw Exception('Geçersiz koordinatlar');
      }

      debugPrint('🌍 Konum bazlı hava durumu isteği: $lat, $lon');
      
      final response = await http.get(
        Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon&units=metric&lang=tr&appid=$apiKey'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Bağlantı zaman aşımına uğradı'),
      );

      debugPrint('📡 API yanıtı alındı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
      debugPrint('📡 API yanıtı: ${data}');

        if (data == null) {
          throw Exception('API yanıtı boş');
        }
        return _parseWeatherData(data);
      } else {
        throw Exception('Hava durumu verileri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Konum bazlı hava durumu verisi alınırken hata: $e');
      rethrow;
    }
  }

  Future<List<WeatherModel>> get5DayForecast(String city) async {
    try {
      if (city.isEmpty) {
        throw Exception('Şehir adı boş olamaz');
      }

      debugPrint('🌍 5 günlük tahmin isteği gönderiliyor: $city');
      
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?q=$city&units=metric&lang=tr&appid=$apiKey'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Bağlantı zaman aşımına uğradı'),
      );

      debugPrint('📡 5 günlük tahmin yanıtı alındı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📡 5 günlük tahmin verisi: $data');
        
        if (data == null || !data.containsKey('list')) {
          throw Exception('Geçersiz API yanıtı');
        }

        final List forecastList = data['list'];
        if (forecastList.isEmpty) {
          return [];
        }
        
        // Günlük gruplandırma
        final Map<String, List<dynamic>> dailyForecasts = {};
        final String cityName = data['city']?['name'] ?? city;
        
        for (var item in forecastList) {
          if (item == null) continue;
          
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateString = '${date.year}-${date.month}-${date.day}';
          
          if (!dailyForecasts.containsKey(dateString)) {
            dailyForecasts[dateString] = [];
          }
          
          dailyForecasts[dateString]!.add(item);
        }
        
        final List<WeatherModel> forecast = [];
        
        dailyForecasts.forEach((date, forecasts) {
          if (forecasts.isNotEmpty) {
            final middleIndex = (forecasts.length / 2).floor();
            forecast.add(_parseForecastData(forecasts[middleIndex], cityName));
          }
        });
        
        return forecast;
      } else if (response.statusCode == 404) {
        throw Exception('Şehir bulunamadı: $city');
      } else {
        throw Exception('Tahmin verileri alınamadı (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ 5 günlük tahmin alınırken hata: $e');
      rethrow;
    }
  }

  WeatherModel _parseWeatherData(Map<String, dynamic> data) {
    try {
      debugPrint('🔍 Hava durumu verisi ayrıştırılıyor...');
      
      // Temel kontroller
      if (!data.containsKey('weather') || data['weather'].isEmpty) {
        throw Exception('Hava durumu verisi eksik');
      }

      final weather = data['weather'][0] as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;
      final name = data['name'] as String;
      final sys = data['sys'] as Map<String, dynamic>?;
      final coord = data['coord'] as Map<String, dynamic>?;

      debugPrint('📍 Konum: $name, ${sys?['country'] ?? 'Bilinmeyen Ülke'}');
      debugPrint('🌍 Koordinatlar: ${coord?['lat'] ?? 'N/A'}, ${coord?['lon'] ?? 'N/A'}');
      debugPrint('🌡️ Sıcaklık: ${main['temp']}°C');
      debugPrint('💨 Rüzgar: ${wind['speed']} m/s');

      return WeatherModel(
        temperature: (main['temp'] ?? 0).toDouble(),
        feelsLike: (main['feels_like'] ?? 0).toDouble(),
        humidity: main['humidity'] ?? 0,
        windSpeed: (wind['speed'] ?? 0).toDouble(),
        description: weather['description'] ?? '',
        condition: _mapWeatherCondition(weather['main'] ?? ''),
        icon: weather['icon'] ?? '01d',
        timestamp: DateTime.fromMillisecondsSinceEpoch((data['dt'] ?? 0) * 1000),
        location: name,
        country: sys?['country'],
        latitude: coord?['lat']?.toDouble(),
        longitude: coord?['lon']?.toDouble(),
      );
    } catch (e) {
      debugPrint('❌ Veri ayrıştırma hatası: $e');
      debugPrint('❌ Gelen veri: $data');
      rethrow;
    }
  }

  WeatherModel _parseForecastData(Map<String, dynamic> data, String cityName) {
    try {
      debugPrint('🔍 Tahmin verisi ayrıştırılıyor...');
      
      if (!data.containsKey('weather') || data['weather'].isEmpty) {
        throw Exception('Hava durumu verisi eksik');
      }

      final weather = data['weather'][0] as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;

      debugPrint('📅 Tarih: ${data['dt_txt']}');
      debugPrint('📍 Konum: $cityName');
      debugPrint('🌡️ Sıcaklık: ${main['temp']}°C');
      debugPrint('💨 Rüzgar: ${wind['speed']} m/s');

      return WeatherModel(
        temperature: (main['temp'] ?? 0).toDouble(),
        feelsLike: (main['feels_like'] ?? 0).toDouble(),
        humidity: main['humidity'] ?? 0,
        windSpeed: (wind['speed'] ?? 0).toDouble(),
        description: weather['description'] ?? '',
        condition: _mapWeatherCondition(weather['main'] ?? ''),
        icon: weather['icon'] ?? '01d',
        timestamp: DateTime.fromMillisecondsSinceEpoch((data['dt'] ?? 0) * 1000),
        location: cityName,
      );
    } catch (e) {
      debugPrint('❌ Tahmin verisi ayrıştırma hatası: $e');
      debugPrint('❌ Gelen veri: $data');
      rethrow;
    }
  }
  
  WeatherCondition _mapWeatherCondition(String condition) {
    debugPrint('🌤️ Hava durumu durumu: $condition');
    
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherCondition.sunny;
      case 'clouds':
        return WeatherCondition.cloudy;
      case 'rain':
      case 'drizzle':
        return WeatherCondition.rainy;
      case 'thunderstorm':
        return WeatherCondition.stormy;
      case 'snow':
        return WeatherCondition.snowy;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return WeatherCondition.foggy;
      default:
        debugPrint('⚠️ Bilinmeyen hava durumu durumu: $condition');
        return WeatherCondition.any;
    }
  }
} 