import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/services/color_analysis_service.dart';

// ClothingFilter sınıfı - Kıyafet filtreleme için
class ClothingFilter {
  final List<ClothingType>? types;
  final List<Season>? seasons;
  final List<String>? colors;
  final String? searchQuery;

  ClothingFilter({
    this.types,
    this.seasons,
    this.colors,
    this.searchQuery,
  });
}

// Filtrelenmiş kıyafetler için provider
final filteredClothingItemsProvider = Provider.family<List<ClothingItemModel>, ClothingFilter>((ref, filter) {
  final items = ref.watch(clothingItemsProvider);
  
  if (filter.types == null && filter.seasons == null && 
      filter.colors == null && (filter.searchQuery == null || filter.searchQuery!.isEmpty)) {
    return items;
  }
  
  return items.where((item) {
    // Tür filtresi
    if (filter.types != null && filter.types!.isNotEmpty && !filter.types!.contains(item.type)) {
      return false;
    }
    
    // Mevsim filtresi
    if (filter.seasons != null && filter.seasons!.isNotEmpty && 
        !item.seasons.any((season) => filter.seasons!.contains(season))) {
      return false;
    }
    
    // Renk filtresi
    if (filter.colors != null && filter.colors!.isNotEmpty && 
        !item.colors.any((color) => filter.colors!.contains(color))) {
      return false;
    }
    
    // Arama sorgusu filtresi
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      if (!item.name.toLowerCase().contains(query) && 
          !(item.brand?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }
    
    return true;
  }).toList();
});

// Renk analizi servisi provider
final colorAnalysisServiceProvider = Provider<ColorAnalysisService>((ref) {
  return ColorAnalysisService();
});

// TODO: Gerçek uygulamada bu provider'lar bir repository ile API'lere bağlanacak

// Kıyafet listesi provider (CRUD işlemleri için notifier kullanılacak)
final clothingItemsProvider = StateNotifierProvider<ClothingItemsNotifier, List<ClothingItemModel>>((ref) {
  return ClothingItemsNotifier();
});

// Kıyafet listesini yöneten notifier
class ClothingItemsNotifier extends StateNotifier<List<ClothingItemModel>> {
  ClothingItemsNotifier() : super([]) {
    // Başlangıçta demo verileri yükle
    loadItems();
  }

  void loadItems() {
    // Gerçek uygulamada: Veritabanından veya API'den yükleme
    final now = DateTime.now();
    state = [
      ClothingItemModel(
        id: '1',
        userId: 'user1',
        name: 'Mavi Tişört',
        type: ClothingType.tShirt,
        colors: ['#2196F3'],
        seasons: [Season.spring, Season.summer],
        material: 'Pamuk',
        brand: 'Marka A',
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
      ClothingItemModel(
        id: '2',
        userId: 'user1',
        name: 'Siyah Pantolon',
        type: ClothingType.pants,
        colors: ['#000000'],
        seasons: [Season.fall, Season.winter, Season.spring],
        material: 'Keten',
        brand: 'Marka B',
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  void addItem(ClothingItemModel item) {
    state = [...state, item];
  }

  void updateItem(ClothingItemModel item) {
    state = [
      for (final existingItem in state)
        if (existingItem.id == item.id) item else existingItem
    ];
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

// Kombin listesi provider
final outfitsProvider = StateNotifierProvider<OutfitsNotifier, List<OutfitModel>>((ref) {
  return OutfitsNotifier();
});

// Kombin listesini yöneten notifier
class OutfitsNotifier extends StateNotifier<List<OutfitModel>> {
  OutfitsNotifier() : super([]) {
    // Başlangıçta demo verileri yükle
    loadOutfits();
  }

  void loadOutfits() {
    // Gerçek uygulamada: Veritabanından veya API'den yükleme
    final now = DateTime.now();
    state = [
      OutfitModel(
        id: '1',
        userId: 'user1',
        name: 'Günlük Kombin',
        description: 'Rahat günlük kullanım için',
        clothingItemIds: ['1', '2'],
        seasons: [Season.spring, Season.summer],
        weatherConditions: [WeatherCondition.sunny, WeatherCondition.partlyCloudy],
        occasion: Occasion.casual,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  void addOutfit(OutfitModel outfit) {
    state = [...state, outfit];
  }

  void updateOutfit(OutfitModel outfit) {
    state = [
      for (final existingOutfit in state)
        if (existingOutfit.id == outfit.id) outfit else existingOutfit
    ];
  }

  void deleteOutfit(String id) {
    state = state.where((outfit) => outfit.id != id).toList();
  }
}

// Kıyafet filtreleri için provider
final clothingItemFiltersProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {}; // Boş filtre ile başla
});

// Kombinleri hava durumuna göre filtreleme provider'ı
final weatherFilteredOutfitsProvider = Provider<List<OutfitModel>>((ref) {
  final outfits = ref.watch(outfitsProvider);
  // TODO: Hava durumu provider'ı ile entegre et
  
  return outfits; // Şimdilik filtreleme yapmıyoruz
});

// Kombin detayları (kıyafetlerle birlikte) için provider
final outfitDetailsProvider = Provider.family<OutfitModel, String>((ref, outfitId) {
  final outfits = ref.watch(outfitsProvider);
  final clothes = ref.watch(clothingItemsProvider);
  
  final outfit = outfits.firstWhere((outfit) => outfit.id == outfitId);
  
  // Kombin ile eşleşen kıyafetleri bul
  final outfitClothes = clothes.where(
    (item) => outfit.clothingItemIds.contains(item.id)
  ).toList();
  
  // Kombini kıyafetlerle birlikte döndür
  return outfit.copyWith(clothingItems: outfitClothes);
}); 