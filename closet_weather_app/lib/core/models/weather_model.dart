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
  final String? country;
  final double? latitude;
  final double? longitude;

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
    this.country,
    this.latitude,
    this.longitude,
  });

  // copyWith metodu - nesneyi değişikliklerle kopyalamak için
  WeatherModel copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    String? description,
    WeatherCondition? condition,
    String? icon,
    DateTime? timestamp,
    String? location,
    String? country,
    double? latitude,
    double? longitude,
  }) {
    return WeatherModel(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Demo verileri oluşturmak için yardımcı factory metodu
  factory WeatherModel.demo() {
    return WeatherModel(
      temperature: 22.5,
      feelsLike: 24.0,
      humidity: 65,
      windSpeed: 12.0,
      condition: WeatherCondition.partlyCloudy,
      description: 'Parçalı bulutlu',
      icon: '02d',
      timestamp: DateTime.now(),
      location: 'İstanbul',
      country: 'TR',
      latitude: 41.0082,
      longitude: 28.9784,
    );
  }

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
      country: json['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
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