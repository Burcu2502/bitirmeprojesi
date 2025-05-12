import 'clothing_item_model.dart';

class OutfitModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> clothingItemIds;
  final List<Season> seasons;
  final List<WeatherCondition> weatherConditions;
  final Occasion occasion;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional runtime field, not stored in database
  final List<ClothingItemModel>? clothingItems;

  OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.clothingItemIds,
    required this.seasons,
    required this.weatherConditions,
    required this.occasion,
    required this.createdAt,
    required this.updatedAt,
    this.clothingItems,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      clothingItemIds: List<String>.from(json['clothing_item_ids']),
      seasons: (json['seasons'] as List)
          .map((season) => Season.values.firstWhere(
                (s) => s.toString() == 'Season.${season}',
                orElse: () => Season.all,
              ))
          .toList(),
      weatherConditions: (json['weather_conditions'] as List)
          .map((condition) => WeatherCondition.values.firstWhere(
                (c) => c.toString() == 'WeatherCondition.${condition}',
                orElse: () => WeatherCondition.any,
              ))
          .toList(),
      occasion: Occasion.values.firstWhere(
        (occasion) => occasion.toString() == 'Occasion.${json['occasion']}',
        orElse: () => Occasion.casual,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'clothing_item_ids': clothingItemIds,
      'seasons': seasons.map((s) => s.toString().split('.').last).toList(),
      'weather_conditions': weatherConditions.map((c) => c.toString().split('.').last).toList(),
      'occasion': occasion.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OutfitModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? clothingItemIds,
    List<Season>? seasons,
    List<WeatherCondition>? weatherConditions,
    Occasion? occasion,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClothingItemModel>? clothingItems,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      clothingItemIds: clothingItemIds ?? this.clothingItemIds,
      seasons: seasons ?? this.seasons,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      occasion: occasion ?? this.occasion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clothingItems: clothingItems ?? this.clothingItems,
    );
  }
}

enum WeatherCondition {
  sunny,
  cloudy,
  partlyCloudy,
  rainy,
  stormy,
  snowy,
  windy,
  foggy,
  hot,
  cold,
  mild,
  any,
}

enum Occasion {
  casual,
  formal,
  business,
  sports,
  party,
  beach,
  home,
  travel,
  other,
} 