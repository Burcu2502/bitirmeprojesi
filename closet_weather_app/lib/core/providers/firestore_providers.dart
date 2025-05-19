import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';

// Firestore servisi provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Kullanıcının kıyafetlerini getiren provider
final userClothingItemsProvider = FutureProvider<List<ClothingItemModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return [];
  }
  
  return firestoreService.getUserClothingItems(user.uid);
});

// Kullanıcının kombinlerini getiren provider
final userOutfitsProvider = FutureProvider<List<OutfitModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return [];
  }
  
  return firestoreService.getUserOutfits(user.uid);
});

// Hava durumuna göre filtrelenmiş kombinleri getiren provider
final weatherBasedOutfitsProvider = FutureProvider.family<List<OutfitModel>, List<String>>((ref, weatherConditions) async {
  final outfits = await ref.watch(userOutfitsProvider.future);
  
  // Hava durumuna uygun kombinleri filtrele
  return outfits.where((outfit) {
    return outfit.weatherConditions.any((condition) => 
      weatherConditions.contains(condition.toString().split('.').last));
  }).toList();
}); 