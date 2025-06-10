import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  final StorageService _storageService = StorageService();
  
  // Koleksiyon referansları
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Alt koleksiyon referansları için yardımcı metotlar
  CollectionReference _clothingItemsCollection(String userId) => 
      _usersCollection.doc(userId).collection('clothing_items');
  
  CollectionReference _outfitsCollection(String userId) => 
      _usersCollection.doc(userId).collection('outfits');

  // Kullanıcı işlemleri
  Future<void> createUser(UserModel user) async {
    try {
      debugPrint("📝 Firestore'da kullanıcı oluşturuluyor: ${user.id} - ${user.name}");
      debugPrint("   - Email: ${user.email}");
      debugPrint("   - Photo URL: ${user.photoUrl}");
      
      final userData = user.toJson();
      debugPrint("   - JSON verisi: ${userData.toString().substring(0, userData.toString().length > 200 ? 200 : userData.toString().length)}...");
      
      await _usersCollection.doc(user.id).set(userData);
      debugPrint("✅ Kullanıcı başarıyla Firestore'da oluşturuldu: ${user.id}");
    } catch (e) {
      debugPrint("❌ Firestore kullanıcı oluşturma hatası: $e");
      debugPrint("❌ User ID: ${user.id}");
      debugPrint("❌ User Name: ${user.name}");
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      debugPrint("🔍 Firestore'dan kullanıcı getiriliyor: $userId");
      
      final doc = await _usersCollection.doc(userId).get();
      debugPrint("   - Doküman var mı: ${doc.exists}");
      debugPrint("   - Data null mu: ${doc.data() == null}");
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint("   - Alınan veri: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...");
        
        final user = UserModel.fromJson(data);
        debugPrint("✅ Kullanıcı Firestore'dan başarıyla getirildi: ${user.name}");
        return user;
      } else {
        debugPrint("⚠️ Kullanıcı Firestore'da bulunamadı: $userId");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Firestore kullanıcı getirme hatası: $e");
      debugPrint("❌ User ID: $userId");
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Kıyafet işlemleri
  Future<String> addClothingItem(ClothingItemModel item) async {
    try {
      // İnternet bağlantısını kontrol et
      final hasConnectivity = await _connectivityService.checkConnectivity();
      if (!hasConnectivity) {
        throw Exception('İnternet bağlantınız yok. Lütfen bağlantınızı kontrol edip tekrar deneyin.');
      }

      // Debug log ekleyelim
      debugPrint("💾 FirestoreService - Kıyafet ekleme işlemi başladı: ${item.name}");
      
      // Gelen modelde gerekli alanların olup olmadığını kontrol et
      if (item.userId.isEmpty) {
        throw Exception('Kullanıcı ID boş olamaz');
      }
      
      if (item.name.isEmpty) {
        throw Exception('Kıyafet adı boş olamaz');
      }
      
      if (item.colors.isEmpty) {
        debugPrint("⚠️ Uyarı: Kıyafet renk bilgisi girilmemiş");
      }
      
      if (item.seasons.isEmpty) {
        debugPrint("⚠️ Uyarı: Kıyafet mevsim bilgisi girilmemiş");
      }
      
      // Alt koleksiyon referansını alıyoruz
      final docRef = _clothingItemsCollection(item.userId).doc();
      debugPrint("📄 Doküman referansı oluşturuldu: ${docRef.id}");
      
      // Belgeyi Firestore ID'si ile güncelliyoruz
      final updatedItem = item.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // JSON verisini debug olarak gösterelim
      final json = updatedItem.toJson();
      debugPrint("🔄 Firestore'a gönderilecek veri: ${json.toString().substring(0, json.toString().length > 100 ? 100 : json.toString().length)}...");
      
      // Firestore'a belgeyi set ediyoruz
      await docRef.set(json);
      
      debugPrint("✅ Kıyafet başarıyla Firestore'a eklendi: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("❌ Firestore kıyafet ekleme hatası: $e");
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firestore yazma izni reddedildi. Kullanıcı yetkilendirmesi kontrol edilmeli: $e');
      } else if (e.toString().contains('INVALID_ARGUMENT')) {
        throw Exception('Geçersiz veri formatı. Firestore verilerini kontrol edin: $e');
      } else if (e.toString().contains('NOT_FOUND')) {
        throw Exception('Koleksiyon veya belge bulunamadı: $e');
      } else {
        throw Exception('Kıyafet Firestore\'a eklenirken hata oluştu: $e');
      }
    }
  }

  Future<List<ClothingItemModel>> getUserClothingItems(String userId) async {
    try {
      // İnternet bağlantısını kontrol et
      final hasConnectivity = await _connectivityService.checkConnectivity();
      if (!hasConnectivity) {
        debugPrint("⚠️ İnternet bağlantısı yok - Kıyafetler yüklenemedi");
        return []; // İnternet yoksa boş liste dön
      }

      final snapshot = await _clothingItemsCollection(userId).get();
      return snapshot.docs
          .map((doc) => ClothingItemModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("❌ Kıyafetler yüklenirken hata: $e");
      return []; // Hata durumunda boş liste dön
    }
  }

  Future<void> updateClothingItem(ClothingItemModel item) async {
    try {
      final updatedItem = item.copyWith(updatedAt: DateTime.now());
      await _clothingItemsCollection(item.userId).doc(item.id).update(updatedItem.toJson());
    } catch (e) {
      throw Exception('Failed to update clothing item: $e');
    }
  }

  Future<void> deleteClothingItem(String userId, String itemId) async {
    try {
      // Önce kıyafet bilgilerini al (resim URL'sini almak için)
      final doc = await _clothingItemsCollection(userId).doc(itemId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['image_url'] as String?;
        
        // Firebase Storage'dan resmi sil
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await _storageService.deleteImage(imageUrl);
            debugPrint("✅ Kıyafet resmi Firebase Storage'dan silindi: $imageUrl");
          } catch (e) {
            debugPrint("⚠️ Firebase Storage'dan resim silinirken hata: $e");
            // Storage hatası Firestore silme işlemini engellemez
          }
        }
      }
      
      // Firestore'dan kıyafeti sil
      await _clothingItemsCollection(userId).doc(itemId).delete();
      debugPrint("✅ Kıyafet Firestore'dan silindi: $itemId");
    } catch (e) {
      debugPrint("❌ Kıyafet silme hatası: $e");
      throw Exception('Kıyafet silinemedi: $e');
    }
  }

  // Kombin işlemleri
  Future<String> addOutfit(OutfitModel outfit) async {
    try {
      final docRef = _outfitsCollection(outfit.userId).doc();
      final updatedOutfit = outfit.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(updatedOutfit.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add outfit: $e');
    }
  }

  Future<List<OutfitModel>> getUserOutfits(String userId) async {
    try {
      final snapshot = await _outfitsCollection(userId).get();
          
      return snapshot.docs
          .map((doc) => OutfitModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user outfits: $e');
    }
  }

  Future<void> updateOutfit(OutfitModel outfit) async {
    try {
      final updatedOutfit = outfit.copyWith(updatedAt: DateTime.now());
      await _outfitsCollection(outfit.userId).doc(outfit.id).update(updatedOutfit.toJson());
    } catch (e) {
      throw Exception('Failed to update outfit: $e');
    }
  }

  Future<void> deleteOutfit(String userId, String outfitId) async {
    try {
      // Firestore'dan kombini sil
      await _outfitsCollection(userId).doc(outfitId).delete();
      debugPrint("✅ Kombin Firestore'dan silindi: $outfitId");
      
      // Not: Kombin resimleri genellikle kıyafet resimlerinin kombinasyonudur
      // Eğer özel kombin resimleri varsa burada silinebilir
    } catch (e) {
      debugPrint("❌ Kombin silme hatası: $e");
      throw Exception('Kombin silinemedi: $e');
    }
  }
  
  // Kullanıcı hesabını tamamen sil (tüm veriler ve resimler dahil)
  Future<void> deleteUserAccount(String userId) async {
    try {
      debugPrint("🗑️ Kullanıcı hesabı siliniyor: $userId");
      
      // Tüm kıyafet resimlerini Firebase Storage'dan sil
      await _storageService.deleteAllUserClothingImages(userId);
      
      // Tüm kombin resimlerini Firebase Storage'dan sil
      await _storageService.deleteAllUserOutfitImages(userId);
      
      // Tüm kıyafetleri Firestore'dan sil
      final clothingSnapshot = await _clothingItemsCollection(userId).get();
      for (final doc in clothingSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Tüm kombinleri Firestore'dan sil
      final outfitsSnapshot = await _outfitsCollection(userId).get();
      for (final doc in outfitsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Kullanıcı profilini sil
      await _usersCollection.doc(userId).delete();
      
      debugPrint("✅ Kullanıcı hesabı tamamen silindi: $userId");
    } catch (e) {
      debugPrint("❌ Kullanıcı hesabı silme hatası: $e");
      throw Exception('Kullanıcı hesabı silinemedi: $e');
    }
  }
} 