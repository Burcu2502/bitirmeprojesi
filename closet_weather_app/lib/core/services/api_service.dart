import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/outfit_model.dart';

class ApiService {
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String apiKey = '3a1234a522faa5171f59468129ed45dc'; // Production'da environment variables'a taşınmalı

  Future<WeatherModel> getCurrentWeather(String city) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/weather?q=$city&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseWeatherData(data, city);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting weather data: $e');
    }
  }

  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseWeatherData(data, data['name']);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting weather data: $e');
    }
  }

  Future<List<WeatherModel>> get5DayForecast(String city) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/forecast?q=$city&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List forecastList = data['list'];
        
        // Group by day and take the middle reading of each day
        final Map<String, List<dynamic>> dailyForecasts = {};
        
        for (var item in forecastList) {
          // Get date without time
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateString = '${date.year}-${date.month}-${date.day}';
          
          if (!dailyForecasts.containsKey(dateString)) {
            dailyForecasts[dateString] = [];
          }
          
          dailyForecasts[dateString]!.add(item);
        }
        
        final List<WeatherModel> forecast = [];
        
        dailyForecasts.forEach((date, forecasts) {
          // Take the forecast from the middle of the day (noon)
          final middleIndex = (forecasts.length / 2).floor();
          forecast.add(_parseWeatherData(forecasts[middleIndex], city));
        });
        
        return forecast;
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting forecast data: $e');
    }
  }

  WeatherModel _parseWeatherData(Map<String, dynamic> data, String location) {
    return WeatherModel(
      temperature: data['main']['temp'].toDouble(),
      feelsLike: data['main']['feels_like'].toDouble(),
      humidity: data['main']['humidity'],
      windSpeed: data['wind']['speed'].toDouble(),
      description: data['weather'][0]['description'],
      condition: _mapWeatherCondition(data['weather'][0]['main']),
      icon: data['weather'][0]['icon'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000),
      location: location,
    );
  }
  
  WeatherCondition _mapWeatherCondition(String condition) {
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
        return WeatherCondition.any;
    }
  }
} 