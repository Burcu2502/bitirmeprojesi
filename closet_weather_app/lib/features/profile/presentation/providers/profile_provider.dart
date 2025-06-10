import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile_model.dart';

// Profil durumu
enum ProfileStatus {
  initial,
  loading,
  loaded,
  error,
}

// Profil durumu için veri sınıfı
class ProfileState {
  final ProfileStatus status;
  final ProfileModel? profile;
  final String? errorMessage;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Profil repository sağlayıcısı
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// Profil durumu sağlayıcısı
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final authStateProvider = ref.watch(authProvider);
  
  return ProfileNotifier(repository, ref, authStateProvider.user != null);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref, bool isLoggedIn) : super(ProfileState()) {
    if (isLoggedIn) {
      loadUserProfile();
    }
  }

  // Kullanıcı profilini yükle
  Future<void> loadUserProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    
    try {
      final profile = await _repository.getUserProfile();
      
      if (profile != null) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
        );
        debugPrint('✅ Profil yüklendi: ${profile.name}');
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profil bulunamadı',
        );
        debugPrint('❌ Profil bulunamadı');
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Profil yüklenirken hata oluştu: $e',
      );
      debugPrint('❌ Profil yükleme hatası: $e');
    }
  }

  // Profil bilgilerini güncelle
  Future<bool> updateProfile({
    required String name,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    if (state.profile == null) {
      debugPrint('❌ Güncellenecek profil bulunamadı');
      return false;
    }
    
    state = state.copyWith(status: ProfileStatus.loading);
    
    try {
      final updatedProfile = state.profile!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        preferences: preferences,
        updatedAt: DateTime.now(),
      );
      
      final success = await _repository.saveProfile(updatedProfile);
      
      if (success) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: updatedProfile,
        );
        debugPrint('✅ Profil güncellendi: $name');
        return true;
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profil güncellenemedi',
        );
        debugPrint('❌ Profil güncellenemedi');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Profil güncellenirken hata oluştu: $e',
      );
      debugPrint('❌ Profil güncelleme hatası: $e');
      return false;
    }
  }
  
  // Tercihleri güncelle
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    if (state.profile == null) {
      debugPrint('❌ Güncellenecek profil bulunamadı');
      return false;
    }
    
    state = state.copyWith(status: ProfileStatus.loading);
    
    try {
      final updatedProfile = state.profile!.copyWith(
        preferences: preferences,
        updatedAt: DateTime.now(),
      );
      
      final success = await _repository.saveProfile(updatedProfile);
      
      if (success) {
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: updatedProfile,
        );
        debugPrint('✅ Profil tercihleri güncellendi');
        return true;
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profil tercihleri güncellenemedi',
        );
        debugPrint('❌ Profil tercihleri güncellenemedi');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Profil tercihleri güncellenirken hata oluştu: $e',
      );
      debugPrint('❌ Profil tercihleri güncelleme hatası: $e');
      return false;
    }
  }

  // Profil fotoğrafını güncelle
  Future<bool> updateProfilePhoto(String photoURL) async {
    if (state.profile == null) {
      debugPrint('❌ Güncellenecek profil bulunamadı');
      return false;
    }
    
    state = state.copyWith(status: ProfileStatus.loading);
    
    try {
      final updatedPhotoURL = await _repository.updateProfilePhoto(photoURL);
      
      if (updatedPhotoURL != null) {
        final updatedProfile = state.profile!.copyWith(
          photoURL: updatedPhotoURL,
          updatedAt: DateTime.now(),
        );
        
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: updatedProfile,
        );
        debugPrint('✅ Profil fotoğrafı güncellendi');
        return true;
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profil fotoğrafı güncellenemedi',
        );
        debugPrint('❌ Profil fotoğrafı güncellenemedi');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Profil fotoğrafı güncellenirken hata oluştu: $e',
      );
      debugPrint('❌ Profil fotoğrafı güncelleme hatası: $e');
      return false;
    }
  }

  // Şifre değiştir
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      debugPrint('🔐 Şifre değiştirme işlemi başlatılıyor...');
      final success = await _repository.changePassword(currentPassword, newPassword);
      
      if (success) {
        debugPrint('✅ Şifre başarıyla değiştirildi (ProfileProvider)');
      } else {
        debugPrint('❌ Şifre değiştirilemedi (ProfileProvider)');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ ProfileProvider şifre değiştirme hatası: $e');
      
      // Exception'ı yeniden fırlat ki UI katmanında yakalanabilsin
      rethrow;
    }
  }
} 