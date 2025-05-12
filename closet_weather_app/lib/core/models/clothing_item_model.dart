class ClothingItemModel {
  final String id;
  final String userId;
  final String name;
  final ClothingType type;
  final List<String> colors;
  final List<Season> seasons;
  final String? material;
  final String? brand;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClothingItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.colors,
    required this.seasons,
    this.material,
    this.brand,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClothingItemModel.fromJson(Map<String, dynamic> json) {
    return ClothingItemModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: ClothingType.values.firstWhere(
        (type) => type.toString() == 'ClothingType.${json['type']}',
        orElse: () => ClothingType.other,
      ),
      colors: List<String>.from(json['colors']),
      seasons: (json['seasons'] as List)
          .map((season) => Season.values.firstWhere(
                (s) => s.toString() == 'Season.${season}',
                orElse: () => Season.all,
              ))
          .toList(),
      material: json['material'],
      brand: json['brand'],
      imageUrl: json['image_url'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'colors': colors,
      'seasons': seasons.map((s) => s.toString().split('.').last).toList(),
      'material': material,
      'brand': brand,
      'image_url': imageUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ClothingItemModel copyWith({
    String? id,
    String? userId,
    String? name,
    ClothingType? type,
    List<String>? colors,
    List<Season>? seasons,
    String? material,
    String? brand,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClothingItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      colors: colors ?? this.colors,
      seasons: seasons ?? this.seasons,
      material: material ?? this.material,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ClothingType {
  tShirt,
  shirt,
  blouse,
  sweater,
  jacket,
  coat,
  jeans,
  pants,
  shorts,
  skirt,
  dress,
  shoes,
  boots,
  accessory,
  hat,
  scarf,
  other,
}

enum Season {
  spring,
  summer,
  fall,
  winter,
  all,
} 