import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  final Location location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      debugPrint('📍 LocationService: Konum alma işlemi başlatılıyor...');
      
      // Konum servislerinin aktif olup olmadığını kontrol et
      bool serviceEnabled = await location.serviceEnabled();
      debugPrint('📍 LocationService: Konum servisleri aktif mi? $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('📍 LocationService: Konum servisleri kapalı, açılması isteniyor...');
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          debugPrint('❌ LocationService: Konum servisleri açılamadı');
          return null;
        }
        debugPrint('✅ LocationService: Konum servisleri başarıyla açıldı');
      }

      // İzin durumunu kontrol et
      PermissionStatus permission = await location.hasPermission();
      debugPrint('📍 LocationService: Mevcut izin durumu: $permission');
      
      if (permission == PermissionStatus.denied) {
        debugPrint('📍 LocationService: İzin reddedilmiş, izin isteniyor...');
        permission = await location.requestPermission();
        debugPrint('📍 LocationService: Yeni izin durumu: $permission');
        
        if (permission != PermissionStatus.granted) {
          debugPrint('❌ LocationService: Konum izni verilmedi');
          return null;
        }
        debugPrint('✅ LocationService: Konum izni başarıyla verildi');
      }

      // Konum verilerini al
      debugPrint('📍 LocationService: Konum verisi alınıyor...');
      final locationData = await location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        debugPrint('✅ LocationService: Konum başarıyla alındı: ${locationData.latitude}, ${locationData.longitude}');
        return locationData;
      } else {
        debugPrint('❌ LocationService: Konum verisi geçersiz (lat/lon null)');
        return null;
      }
      
    } catch (e) {
      debugPrint('❌ LocationService: Konum alınırken hata: $e');
      return null;
    }
  }
}

// Konum durumu için state notifier
class LocationState {
  final LocationData? position;
  final String? selectedCity;
  final String? error;
  final bool isLoading;

  LocationState({
    this.position,
    this.selectedCity,
    this.error,
    this.isLoading = false,
  });

  LocationState copyWith({
    LocationData? position,
    String? selectedCity,
    String? error,
    bool? isLoading,
  }) {
    return LocationState(
      position: position ?? this.position,
      selectedCity: selectedCity ?? this.selectedCity,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationStateNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationStateNotifier(this._locationService) : super(LocationState());

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        state = state.copyWith(
          position: position,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Konum alınamadı',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Konum alınırken hata oluştu: $e',
        isLoading: false,
      );
    }
  }

  void setSelectedCity(String city) {
    state = state.copyWith(selectedCity: city);
  }
}

final locationStateProvider = StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationStateNotifier(locationService);
});