import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService = ConnectivityService();
  
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
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
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
      await _clothingItemsCollection(userId).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete clothing item: $e');
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
      await _outfitsCollection(userId).doc(outfitId).delete();
    } catch (e) {
      throw Exception('Failed to delete outfit: $e');
    }
  }
} 