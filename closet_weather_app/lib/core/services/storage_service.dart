import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  // Firebase Storage referansı - App Check bypass
  late final FirebaseStorage _storage;
  
  // Constructor'da storage'ı yapılandır
  StorageService() {
    _storage = FirebaseStorage.instance;
    // App Check token hatalarını yoksay
    _storage.setMaxUploadRetryTime(const Duration(seconds: 30));
    _storage.setMaxDownloadRetryTime(const Duration(seconds: 30));
  }
  
  // Klasör yapısı
  static const String clothingImagesPath = 'clothing_images';
  static const String outfitImagesPath = 'outfit_images';
  
  // Kıyafet resmini Firebase Storage'a yükler
  Future<String> uploadClothingImage(String userId, File imageFile) async {
    try {
      debugPrint("📸 Resim Firebase Storage'a yükleniyor...");
      
      // *** AUTH DEBUG BAŞLANGIÇ ***
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint("🔐 Firebase Auth Durum Kontrolü:");
      debugPrint("   - Kullanıcı ID: ${currentUser?.uid}");
      debugPrint("   - Email: ${currentUser?.email}");
      debugPrint("   - Auth Token: ${currentUser != null ? 'Var' : 'YOK!'}");
      
      if (currentUser == null) {
        throw Exception('❌ Firebase Auth: Kullanıcı giriş yapmamış!');
      }
      
      if (currentUser.uid != userId) {
        debugPrint("⚠️ UYARI: Auth User ID (${currentUser.uid}) != Verilen User ID ($userId)");
      }
      
      // Auth token'ını kontrol et
      try {
        // Token'ı force refresh et (App Check bypass için)
        final idToken = await currentUser.getIdToken(true); // true = force refresh
        debugPrint("✅ Firebase Auth Token REFRESH edildi: ${idToken?.substring(0, 50) ?? 'NULL TOKEN'}...");
      } catch (e) {
        debugPrint("❌ Firebase Auth Token alınamadı: $e");
        throw Exception('Firebase Auth token alınamadı: $e');
      }
      // *** AUTH DEBUG SON ***
      
      // Dosya varlığını kontrol et
      if (!await imageFile.exists()) {
        throw Exception('Resim dosyası bulunamadı: ${imageFile.path}');
      }
      
      // Dosya boyutunu kontrol et
      final fileSize = await imageFile.length();
      debugPrint("📊 Dosya boyutu: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB");
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Dosya boyutu çok büyük (max 10MB): ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      debugPrint("📁 Dosya adı: $fileName");
      
      // Firebase Storage referansı oluştur
      final Reference storageRef = _storage
          .ref()
          .child(clothingImagesPath)
          .child(userId)
          .child(fileName);
      
      debugPrint("🔗 Storage path: ${storageRef.fullPath}");
      
      // Metadata ayarla
      final metadata = SettableMetadata(
        contentType: 'image/${path.extension(imageFile.path).substring(1)}',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Dosyayı yükle
      debugPrint("⬆️ Upload başlatılıyor...");
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Progress listener ekle
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint("📈 Upload progress: ${progress.toStringAsFixed(1)}%");
      });
      
      // Yükleme tamamlanmasını bekle
      debugPrint("⏳ Upload tamamlanması bekleniyor...");
      final TaskSnapshot snapshot = await uploadTask;
      debugPrint("✅ Upload tamamlandı, snapshot state: ${snapshot.state}");
      
      // Download URL'ini al
      debugPrint("🔗 Download URL alınıyor...");
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      debugPrint("✅ Resim başarıyla Firebase Storage'a yüklendi: $downloadURL");
      return downloadURL;
    } catch (e) {
      debugPrint("❌ Firebase Storage resim yükleme hatası: $e");
      debugPrint("❌ Stack trace: ${StackTrace.current}");
      
      // Spesifik hata mesajları
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebase Storage izin hatası. Lütfen Firebase Rules\'ları kontrol edin.');
      } else if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Firebase Storage yetkilendirme hatası. Giriş yapmış olduğunuzdan emin olun.');
      } else if (e.toString().contains('storage/invalid-url')) {
        throw Exception('Geçersiz Firebase Storage URL');
      } else if (e.toString().contains('network')) {
        throw Exception('İnternet bağlantısı hatası. Bağlantınızı kontrol edin.');
      }
      
      throw Exception('Resim Firebase Storage\'a yüklenemedi: $e');
    }
  }
  
  // Byte array'den resim yükler
  Future<String> uploadClothingImageFromBytes(String userId, Uint8List imageBytes) async {
    try {
      debugPrint("📸 Resim bytes'lardan Firebase Storage'a yükleniyor...");
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}.jpg';
      
      // Firebase Storage referansı oluştur
      final Reference storageRef = _storage
          .ref()
          .child(clothingImagesPath)
          .child(userId)
          .child(fileName);
      
      // Metadata ayarla
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );
      
      // Bytes'ları yükle
      final UploadTask uploadTask = storageRef.putData(imageBytes, metadata);
      
      // Yükleme tamamlanmasını bekle
      final TaskSnapshot snapshot = await uploadTask;
      
      // Download URL'ini al
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      debugPrint("✅ Resim başarıyla Firebase Storage'a yüklendi (bytes): $downloadURL");
      return downloadURL;
    } catch (e) {
      debugPrint("❌ Firebase Storage resim yükleme hatası (bytes): $e");
      throw Exception('Resim Firebase Storage\'a yüklenemedi: $e');
    }
  }
  
  // Kombin resmini Firebase Storage'a yükler
  Future<String> uploadOutfitImage(String userId, File imageFile) async {
    try {
      debugPrint("📸 Kombin resmi Firebase Storage'a yükleniyor...");
      
      // Benzersiz dosya adı oluştur
      final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      
      // Firebase Storage referansı oluştur
      final Reference storageRef = _storage
          .ref()
          .child(outfitImagesPath)
          .child(userId)
          .child(fileName);
      
      // Dosyayı yükle
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Yükleme tamamlanmasını bekle
      final TaskSnapshot snapshot = await uploadTask;
      
      // Download URL'ini al
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      debugPrint("✅ Kombin resmi başarıyla Firebase Storage'a yüklendi: $downloadURL");
      return downloadURL;
    } catch (e) {
      debugPrint("❌ Firebase Storage kombin resmi yükleme hatası: $e");
      throw Exception('Kombin resmi Firebase Storage\'a yüklenemedi: $e');
    }
  }
  
  // Firebase Storage'dan resmi sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.startsWith('http')) {
        // URL'den Firebase Storage referansını al
        final Reference storageRef = _storage.refFromURL(imageUrl);
        
        // Dosyayı sil
        await storageRef.delete();
        
        debugPrint("✅ Resim Firebase Storage'dan silindi: $imageUrl");
      }
    } catch (e) {
      debugPrint("❌ Firebase Storage dosya silme hatası: $e");
      // Dosya zaten silinmiş olabilir, hatayı yutuyoruz
    }
  }
  
  // Kullanıcının tüm kıyafet resimlerini sil
  Future<void> deleteAllUserClothingImages(String userId) async {
    try {
      final Reference userClothingRef = _storage
          .ref()
          .child(clothingImagesPath)
          .child(userId);
      
      final ListResult result = await userClothingRef.listAll();
      
      for (final Reference fileRef in result.items) {
        await fileRef.delete();
      }
      
      debugPrint("✅ Kullanıcının tüm kıyafet resimleri silindi: $userId");
    } catch (e) {
      debugPrint("❌ Kullanıcı kıyafet resimleri silme hatası: $e");
    }
  }
  
  // Kullanıcının tüm kombin resimlerini sil
  Future<void> deleteAllUserOutfitImages(String userId) async {
    try {
      final Reference userOutfitRef = _storage
          .ref()
          .child(outfitImagesPath)
          .child(userId);
      
      final ListResult result = await userOutfitRef.listAll();
      
      for (final Reference fileRef in result.items) {
        await fileRef.delete();
      }
      
      debugPrint("✅ Kullanıcının tüm kombin resimleri silindi: $userId");
    } catch (e) {
      debugPrint("❌ Kullanıcı kombin resimleri silme hatası: $e");
    }
  }
  
  // Firebase Storage bağlantısını test et
  Future<bool> testStorageConnection(String userId) async {
    try {
      debugPrint("🔍 Firebase Storage bağlantısı test ediliyor...");
      
      // Basit bir storage referansı oluşturarak bağlantıyı test et
      final testRef = _storage.ref().child('test').child(userId);
      debugPrint("📦 Storage referansı oluşturuldu: ${testRef.fullPath}");
      
      try {
        // Test referansının metadata'sını almaya çalış
        await testRef.getMetadata();
        debugPrint("✅ Firebase Storage bağlantısı başarılı (metadata alındı)");
      } catch (metadataError) {
        // Metadata alınamıyorsa (dosya yok), bu normal
        final errorString = metadataError.toString();
        final truncatedError = errorString.length > 100 ? errorString.substring(0, 100) + "..." : errorString;
        debugPrint("📝 Test metadata alınamadı (normal - dosya yok): $truncatedError");
        
        // Eğer storage hizmeti tamamen kapalıysa burada ciddi hata alırız
        if (errorString.contains('storage-service-unavailable') || 
            errorString.contains('bucket-not-found')) {
          debugPrint("❌ Storage servisi kapalı veya bucket bulunamadı");
          return false;
        }
        
        debugPrint("✅ Firebase Storage bağlantısı başarılı (bucket erişilebilir)");
      }
      
      return true;
    } catch (e) {
      debugPrint("❌ Firebase Storage bağlantı testi başarısız: $e");
      
      // Spesifik hata kontrolü
      if (e.toString().contains('storage-service-unavailable')) {
        debugPrint("🚨 Firebase Storage servisi aktifleştirilmemiş!");
      } else if (e.toString().contains('bucket-not-found')) {
        debugPrint("🚨 Storage bucket bulunamadı!");
      }
      
      return false;
    }
  }
} 