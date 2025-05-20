class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String? photoURL;
  final String? phoneNumber;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.phoneNumber,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Preferences için güvenli tip dönüşümü
    Map<String, dynamic>? preferencesMap;
    if (json['preferences'] != null) {
      preferencesMap = {};
      try {
        final rawPrefs = json['preferences'] as Map;
        rawPrefs.forEach((key, value) {
          preferencesMap![key.toString()] = value;
        });
      } catch (e) {
        // Sorun durumunda boş map kullan
        preferencesMap = {};
      }
    }
    
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      preferences: preferencesMap,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'preferences': preferences ?? {},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoURL,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 