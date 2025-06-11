import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/services/color_analysis_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';

// ClothingFilter sınıfı - Kıyafet filtreleme için
class ClothingFilter {
  final List<ClothingType>? types;
  final List<Season>? seasons;
  final List<String>? colors; // Renk kodları
  final String? searchQuery;
  final String? brand;
  
  ClothingFilter({
    this.types,
    this.seasons,
    this.colors,
    this.searchQuery,
    this.brand,
  });
  
  ClothingFilter copyWith({
    List<ClothingType>? types,
    List<Season>? seasons,
    List<String>? colors,
    String? searchQuery,
    String? brand,
  }) {
    return ClothingFilter(
      types: types ?? this.types,
      seasons: seasons ?? this.seasons,
      colors: colors ?? this.colors,
      searchQuery: searchQuery ?? this.searchQuery,
      brand: brand ?? this.brand,
    );
  }
}

// Filtrelenmiş kıyafetler için provider
final filteredClothingItemsProvider = Provider.family<AsyncValue<List<ClothingItemModel>>, ClothingFilter>((ref, filter) {
  final itemsAsyncValue = ref.watch(clothingItemsProvider);
  
  return itemsAsyncValue.when(
    data: (items) {
      return AsyncValue.data(_filterItems(items, filter));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

List<ClothingItemModel> _filterItems(List<ClothingItemModel> items, ClothingFilter filter) {
  return items.where((item) {
    // Tür filtresi
    if (filter.types != null && filter.types!.isNotEmpty && 
        !filter.types!.contains(item.type)) {
      return false;
    }
    
    // Sezon filtresi
    if (filter.seasons != null && filter.seasons!.isNotEmpty && 
        !item.seasons.any((season) => filter.seasons!.contains(season))) {
      return false;
    }
    
    // Renk filtresi (hex kodlarını karşılaştır)
    if (filter.colors != null && filter.colors!.isNotEmpty) {
      bool hasAnyColor = false;
      for (final itemColor in item.colors) {
        if (filter.colors!.contains(itemColor.toLowerCase())) {
          hasAnyColor = true;
          break;
        }
      }
      if (!hasAnyColor) return false;
    }
    
    // Arama filtresi
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      if (!item.name.toLowerCase().contains(query) && 
          !(item.brand?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }
    
    // Marka filtresi
    if (filter.brand != null && filter.brand!.isNotEmpty) {
      if (item.brand == null || !item.brand!.toLowerCase().contains(filter.brand!.toLowerCase())) {
        return false;
      }
    }
    
    return true;
  }).toList();
}

// Renk analizi servisi provider
final colorAnalysisProvider = Provider<ColorAnalysisService>((ref) {
  return ColorAnalysisService();
});

// TODO: Gerçek uygulamada bu provider'lar bir repository ile API'lere bağlanacak

// Kıyafet listesi provider (CRUD işlemleri için notifier kullanılacak)
final clothingItemsProvider = StateNotifierProvider<ClothingItemsNotifier, AsyncValue<List<ClothingItemModel>>>((ref) {
  final firestoreService = ref.watch(firestoreProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return ClothingItemsNotifier(firestoreService, userId);
});

// Kıyafet listesini yöneten notifier
class ClothingItemsNotifier extends StateNotifier<AsyncValue<List<ClothingItemModel>>> {
  final FirestoreService _firestoreService;
  final String? _userId;
  
  ClothingItemsNotifier(this._firestoreService, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadItems();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  
  Future<void> loadItems() async {
    if (!mounted) return; // Dispose kontrolü
    
    try {
      state = const AsyncValue.loading();
      if (_userId == null) {
        if (!mounted) return;
        state = const AsyncValue.data([]);
        return;
      }
      
      final items = await _firestoreService.getUserClothingItems(_userId!);
      if (!mounted) return; // Async işlem sonrası kontrol
      state = AsyncValue.data(items);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> addItem(ClothingItemModel item) async {
    if (!mounted) return;
    
    try {
      // Yükleme durumunu güncelleyelim
      final currentItems = state.valueOrNull ?? [];
      
      // Geçici olarak optimistik bir güncellemede bulunuyoruz
      if (!mounted) return;
      state = AsyncValue.data([...currentItems, item]);
      
      // Firestore'a kıyafeti ekliyoruz
      final itemId = await _firestoreService.addClothingItem(item);
      
      // Firebase'den güncel listeyi alalım
      if (!mounted) return;
      await loadItems();
    } catch (e, stackTrace) {
      // Hata durumunda state'i error'a çeviriyoruz
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
  
  Future<void> updateItem(ClothingItemModel item) async {
    if (!mounted) return;
    
    try {
      await _firestoreService.updateClothingItem(item);
      if (!mounted) return;
      loadItems(); // Listeyi yeniden yükle
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteItem(String id) async {
    if (!mounted) return;
    
    try {
      await _firestoreService.deleteClothingItem(_userId!, id);
      if (!mounted) return;
      loadItems(); // Listeyi yeniden yükle
    } catch (e) {
      rethrow;
    }
  }
}

// Kombin listesi provider
final outfitsProvider = StateNotifierProvider<OutfitsNotifier, List<OutfitModel>>((ref) {
  final firestoreService = ref.watch(firestoreProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return OutfitsNotifier(firestoreService, userId);
});

// Kombin listesini yöneten notifier
class OutfitsNotifier extends StateNotifier<List<OutfitModel>> {
  final FirestoreService _firestoreService;
  final String? _userId;
  
  OutfitsNotifier(this._firestoreService, this._userId) : super([]) {
    // Başlangıçta verileri yükle
    loadOutfits();
  }

  Future<void> loadOutfits() async {
    if (!mounted) return;
    
    if (_userId == null) {
      if (!mounted) return;
      state = [];
      return;
    }
    
    try {
      final outfits = await _firestoreService.getUserOutfits(_userId!);
      if (!mounted) return;
      state = outfits;
    } catch (e) {
      debugPrint("❌ Kombin yükleme hatası: $e");
      if (!mounted) return;
      state = [];
    }
  }

  Future<void> addOutfit(OutfitModel outfit) async {
    if (!mounted) return;
    if (_userId == null) return;
    
    try {
      await _firestoreService.addOutfit(outfit);
      if (!mounted) return;
      loadOutfits(); // Listeyi yeniden yükle
    } catch (e) {
      debugPrint("❌ Kombin ekleme hatası: $e");
      rethrow;
    }
  }

  Future<void> updateOutfit(OutfitModel outfit) async {
    if (!mounted) return;
    if (_userId == null) return;
    
    try {
      await _firestoreService.updateOutfit(outfit);
      if (!mounted) return;
      loadOutfits(); // Listeyi yeniden yükle
    } catch (e) {
      debugPrint("❌ Kombin güncelleme hatası: $e");
      rethrow;
    }
  }

  Future<void> deleteOutfit(String id) async {
    if (!mounted) return;
    if (_userId == null) return;
    
    try {
      await _firestoreService.deleteOutfit(_userId!, id);
      if (!mounted) return;
      loadOutfits(); // Listeyi yeniden yükle
    } catch (e) {
      debugPrint("❌ Kombin silme hatası: $e");
      rethrow;
    }
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
  final clothesAsyncValue = ref.watch(clothingItemsProvider);
  
  final outfit = outfits.firstWhere((outfit) => outfit.id == outfitId);
  
  // Kombin ile eşleşen kıyafetleri bul
  final outfitClothes = clothesAsyncValue.when(
    data: (items) => items.where(
      (item) => outfit.clothingItemIds.contains(item.id)
    ).toList(),
    loading: () => <ClothingItemModel>[],
    error: (_, __) => <ClothingItemModel>[],
  );
  
  // Kombini kıyafetlerle birlikte döndür
  return outfit.copyWith(clothingItems: outfitClothes);
});

// Outfit provider
final outfitWithItemsProvider = Provider.family<OutfitModel, String>((ref, outfitId) {
  // TODO: Firestore'dan outfit verilerini çek
  final now = DateTime.now();
  final outfit = OutfitModel(
    id: outfitId,
    userId: 'user1',
    name: 'Günlük Kombin',
    clothingItemIds: ['1', '2'],
    seasons: [Season.spring],
    weatherConditions: [WeatherCondition.sunny, WeatherCondition.mild],
    occasion: Occasion.casual,
    createdAt: now,
    updatedAt: now,
  );
  
  // Kıyafetleri yükle
  final clothingItemsAsyncValue = ref.watch(clothingItemsProvider);
  
  final List<ClothingItemModel> outfitClothes = clothingItemsAsyncValue.when(
    data: (items) => items.where((item) => outfit.clothingItemIds.contains(item.id)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
  
  // Kombini kıyafetlerle birlikte döndür
  return outfit.copyWith(clothingItems: outfitClothes);
});

// Firestore ve Storage servisleri için provider'lar
final firestoreProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageProvider = Provider<StorageService>((ref) {
  return StorageService();
}); 