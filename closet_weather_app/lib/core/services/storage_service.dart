import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/foundation.dart';

class StorageService {
  // Klasör yapısı
  static const String clothingImagesPath = 'clothing_images';
  static const String outfitImagesPath = 'outfit_images';
  
  // Kıyafet resmini lokal depolamaya kaydeder
  Future<String> uploadClothingImage(String userId, File imageFile) async {
    try {
      debugPrint("📸 Resim lokal olarak kaydediliyor...");
      
      // Uygulama dokümanları dizinini al
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      
      // Kıyafet resimleri için klasör oluştur
      final userImagesDir = Directory('${appDir.path}/$clothingImagesPath/$userId');
      if (!await userImagesDir.exists()) {
        await userImagesDir.create(recursive: true);
      }
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      final String filePath = '${userImagesDir.path}/$fileName';
      
      // Dosyayı kopyala
      final File newImage = await imageFile.copy(filePath);
      
      debugPrint("✅ Resim başarıyla lokal olarak kaydedildi: $filePath");
      return filePath; // Dosya yolu döndürülüyor (URL yerine)
    } catch (e) {
      debugPrint("❌ Lokal resim kaydetme hatası: $e");
      throw Exception('Resim kaydedilemedi: $e');
    }
  }
  
  // Byte array'den resim kaydeder
  Future<String> uploadClothingImageFromBytes(String userId, Uint8List imageBytes) async {
    try {
      // Uygulama dokümanları dizinini al
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      
      // Kıyafet resimleri için klasör oluştur
      final userImagesDir = Directory('${appDir.path}/$clothingImagesPath/$userId');
      if (!await userImagesDir.exists()) {
        await userImagesDir.create(recursive: true);
      }
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}.jpg';
      final String filePath = '${userImagesDir.path}/$fileName';
      
      // Dosyayı oluştur ve bytes'ları yaz
      final File newImage = File(filePath);
      await newImage.writeAsBytes(imageBytes);
      
      return filePath; // Dosya yolu döndürülüyor
    } catch (e) {
      debugPrint("❌ Lokal resim kaydetme hatası (bytes): $e");
      throw Exception('Resim kaydedilemedi: $e');
    }
  }
  
  // Kombin resmini lokal depolamaya kaydeder
  Future<String> uploadOutfitImage(String userId, File imageFile) async {
    try {
      // Uygulama dokümanları dizinini al
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      
      // Kombin resimleri için klasör oluştur
      final outfitImagesDir = Directory('${appDir.path}/$outfitImagesPath/$userId');
      if (!await outfitImagesDir.exists()) {
        await outfitImagesDir.create(recursive: true);
      }
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      final String filePath = '${outfitImagesDir.path}/$fileName';
      
      // Dosyayı kopyala
      final File newImage = await imageFile.copy(filePath);
      
      return filePath; // Dosya yolu döndürülüyor
    } catch (e) {
      debugPrint("❌ Lokal resim kaydetme hatası (outfit): $e");
      throw Exception('Resim kaydedilemedi: $e');
    }
  }
  
  // Resmi sil
  Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("❌ Dosya silme hatası: $e");
      throw Exception('Dosya silinemedi: $e');
    }
  }
} 