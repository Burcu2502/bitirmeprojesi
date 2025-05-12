import 'outfit_model.dart';
import 'clothing_item_model.dart';

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final WeatherCondition condition;
  final String icon;
  final DateTime timestamp;
  final String location;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.condition,
    required this.icon,
    required this.timestamp,
    required this.location,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: json['temperature'].toDouble(),
      feelsLike: json['feels_like'].toDouble(),
      humidity: json['humidity'],
      windSpeed: json['wind_speed'].toDouble(),
      description: json['description'],
      condition: _mapCondition(json['condition']),
      icon: json['icon'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feels_like': feelsLike,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'description': description,
      'condition': condition.toString().split('.').last,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
  }

  static WeatherCondition _mapCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return WeatherCondition.sunny;
      case 'clouds':
      case 'cloudy':
        return WeatherCondition.cloudy;
      case 'partly cloudy':
      case 'partly-cloudy':
        return WeatherCondition.partlyCloudy;
      case 'rain':
      case 'rainy':
      case 'light rain':
      case 'moderate rain':
        return WeatherCondition.rainy;
      case 'thunderstorm':
      case 'storm':
        return WeatherCondition.stormy;
      case 'snow':
      case 'snowy':
        return WeatherCondition.snowy;
      case 'wind':
      case 'windy':
        return WeatherCondition.windy;
      case 'fog':
      case 'foggy':
      case 'mist':
        return WeatherCondition.foggy;
      default:
        return WeatherCondition.any;
    }
  }

  // Helper methods to determine clothing recommendations
  bool get isHot => temperature > 28;
  bool get isWarm => temperature >= 23 && temperature <= 28;
  bool get isMild => temperature >= 16 && temperature <= 22;
  bool get isCool => temperature >= 10 && temperature <= 15;
  bool get isCold => temperature < 10;

  // Get season based on temperature and condition
  Season getSeason() {
    if (isHot || isWarm) {
      return Season.summer;
    } else if (isMild) {
      return Season.spring;
    } else if (isCool) {
      return Season.fall;
    } else {
      return Season.winter;
    }
  }
} 