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
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          debugPrint('Konum servisleri devre dışı');
          return null;
        }
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) {
          debugPrint('Konum izni reddedildi');
          return null;
        }
      }

      return await location.getLocation();
    } catch (e) {
      debugPrint('Konum alınırken hata: $e');
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