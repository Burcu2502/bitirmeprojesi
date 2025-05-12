import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Koleksiyon referansları
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _clothingItemsCollection => _firestore.collection('clothing_items');
  CollectionReference get _outfitsCollection => _firestore.collection('outfits');

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
      final docRef = _clothingItemsCollection.doc();
      final updatedItem = item.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(updatedItem.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add clothing item: $e');
    }
  }

  Future<List<ClothingItemModel>> getUserClothingItems(String userId) async {
    try {
      final snapshot = await _clothingItemsCollection
          .where('user_id', isEqualTo: userId)
          .get();
          
      return snapshot.docs
          .map((doc) => ClothingItemModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user clothing items: $e');
    }
  }

  Future<void> updateClothingItem(ClothingItemModel item) async {
    try {
      final updatedItem = item.copyWith(updatedAt: DateTime.now());
      await _clothingItemsCollection.doc(item.id).update(updatedItem.toJson());
    } catch (e) {
      throw Exception('Failed to update clothing item: $e');
    }
  }

  Future<void> deleteClothingItem(String id) async {
    try {
      await _clothingItemsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete clothing item: $e');
    }
  }

  // Kombin işlemleri
  Future<String> addOutfit(OutfitModel outfit) async {
    try {
      final docRef = _outfitsCollection.doc();
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
      final snapshot = await _outfitsCollection
          .where('user_id', isEqualTo: userId)
          .get();
          
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
      await _outfitsCollection.doc(outfit.id).update(updatedOutfit.toJson());
    } catch (e) {
      throw Exception('Failed to update outfit: $e');
    }
  }

  Future<void> deleteOutfit(String id) async {
    try {
      await _outfitsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete outfit: $e');
    }
  }
} 