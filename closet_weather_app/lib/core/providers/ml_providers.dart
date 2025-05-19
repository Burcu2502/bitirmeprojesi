import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ml_service.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
import 'firestore_providers.dart';

// ML servisi provider
final mlServiceProvider = Provider<MLService>((ref) {
  return MLService();
});

// Hava durumuna göre tavsiye edilen kıyafet tipleri provider'ı
final weatherSuitableClothingTypesProvider = Provider.family<List<ClothingType>, WeatherModel>((ref, weather) {
  final mlService = ref.watch(mlServiceProvider);
  return mlService.getSuitableClothingTypesForWeather(weather);
});

// Hava durumuna uygun kıyafetleri filtreleme provider'ı
final weatherFilteredClothingProvider = Provider.family<Future<List<ClothingItemModel>>, WeatherModel>((ref, weather) async {
  // Kullanıcının tüm kıyafetlerini al
  final clothingItems = await ref.watch(userClothingItemsProvider.future);
  
  // Hava durumuna uygun kıyafet tiplerini al
  final suitableTypes = ref.watch(weatherSuitableClothingTypesProvider(weather));
  
  // Uygun kıyafetleri filtrele
  return clothingItems.where((item) => 
    suitableTypes.contains(item.type)
  ).toList();
});

// Renk uyumuna göre kombin önerisi provider'ı
final colorHarmonyOutfitProvider = Provider.family<Future<List<ClothingItemModel>>, ClothingItemModel>((ref, baseItem) async {
  final mlService = ref.watch(mlServiceProvider);
  final clothingItems = await ref.watch(userClothingItemsProvider.future);
  
  // Renk uyumuna göre en iyi 3 kıyafeti öner
  return mlService.suggestOutfitByColorHarmony(clothingItems, baseItem, 3);
}); 