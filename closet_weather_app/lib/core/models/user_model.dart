import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? skinTone;
  final List<String>? stylePreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.skinTone,
    this.stylePreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Style Preferences güvenli dönüşüm
      List<String>? styles;
      if (json['style_preferences'] != null) {
        try {
          final rawPrefs = json['style_preferences'] as List?;
          if (rawPrefs != null) {
            styles = rawPrefs.map((item) => item.toString()).toList();
          }
        } catch (e) {
          debugPrint('⚠️ stylePreferences dönüştürürken hata: $e');
          styles = null;
        }
      }
      
      return UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        skinTone: json['skin_tone'] as String?,
        stylePreferences: styles,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e) {
      debugPrint('❌ UserModel.fromJson hatası: $e');
      // Hata durumunda varsayılan bir model döndür
      return UserModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? 'İsimsiz',
        photoUrl: null,
        skinTone: null,
        stylePreferences: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
        'skin_tone': skinTone,
        'style_preferences': stylePreferences,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ UserModel.toJson hatası: $e');
      // Hata durumunda temel alanları içeren map döndür
      return {
        'id': id,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? skinTone,
    List<String>? stylePreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      skinTone: skinTone ?? this.skinTone,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 