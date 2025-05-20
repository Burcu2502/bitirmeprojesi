import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../domain/models/profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı profil bilgilerini al
  Future<ProfileModel?> getUserProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        debugPrint('❌ Kullanıcı oturum açmamış!');
        return null;
      }
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!docSnapshot.exists) {
        debugPrint('❌ Kullanıcı profili bulunamadı: ${currentUser.uid}');
        // Profil bulunamadıysa Firebase Auth verilerinden oluşturalım
        final newProfile = ProfileModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? 'İsimsiz',
          email: currentUser.email ?? '',
          photoURL: currentUser.photoURL,
          phoneNumber: currentUser.phoneNumber,
          preferences: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Yeni profili Firestore'a kaydedelim
        try {
          await _firestore.collection('users').doc(currentUser.uid).set(
            newProfile.toJson(),
            SetOptions(merge: true),
          );
          debugPrint('✅ Yeni profil oluşturuldu ve kaydedildi: ${currentUser.uid}');
          return newProfile;
        } catch (e) {
          debugPrint('❌ Yeni profil kaydedilirken hata: $e');
          return newProfile; // Yine de profili döndürelim
        }
      }
      
      final data = docSnapshot.data()!;
      
      // Preferences için güvenli tip dönüşümü
      Map<String, dynamic> preferences = {};
      if (data['preferences'] != null) {
        try {
          // Firestore'dan gelen Map'i String key'li Map'e dönüştür
          final rawPreferences = data['preferences'] as Map;
          rawPreferences.forEach((key, value) {
            preferences[key.toString()] = value;
          });
          debugPrint('✅ Preferences başarıyla dönüştürüldü');
        } catch (e) {
          debugPrint('⚠️ Preferences dönüştürülürken hata: $e, boş map kullanılacak');
          // Hata durumunda boş map kullan
          preferences = {};
        }
      }
      
      return ProfileModel.fromJson({
        'id': currentUser.uid,
        'name': data['name'] ?? currentUser.displayName ?? 'İsimsiz',
        'email': data['email'] ?? currentUser.email ?? '',
        'photoURL': data['photoURL'] ?? currentUser.photoURL,
        'phoneNumber': data['phoneNumber'] ?? currentUser.phoneNumber,
        'preferences': preferences,
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Profil getirme hatası: $e');
      return null;
    }
  }

  // Profil oluştur veya güncelle
  Future<bool> saveProfile(ProfileModel profile) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        debugPrint('❌ Kullanıcı oturum açmamış!');
        return false;
      }
      
      // Tip dönüşüm hatasını önlemek için veriyi hazırla
      final profileData = profile.toJson();
      
      // Önce Firestore'a kaydet
      await _firestore.collection('users').doc(currentUser.uid).set(
        profileData,
        SetOptions(merge: true),
      );
      debugPrint('✅ Profil Firestore\'a kaydedildi: ${currentUser.uid}');
      
      // Kullanıcı adını Firebase Auth'da güncelle (ayrı try-catch bloğunda)
      try {
        await currentUser.updateDisplayName(profile.name);
        debugPrint('✅ Firebase Auth displayName güncellendi: ${profile.name}');
      } catch (e) {
        debugPrint('⚠️ displayName güncellenirken hata, ama Firestore güncellendi: $e');
        // Bu hatayı yutuyoruz çünkü Firestore'a kayıt başarılı
      }
      
      // Profil fotoğrafı varsa güncelle (ayrı try-catch bloğunda)
      if (profile.photoURL != null && profile.photoURL != currentUser.photoURL) {
        try {
          await currentUser.updatePhotoURL(profile.photoURL);
          debugPrint('✅ Firebase Auth photoURL güncellendi: ${profile.photoURL}');
        } catch (e) {
          debugPrint('⚠️ photoURL güncellenirken hata, ama Firestore güncellendi: $e');
          // Bu hatayı yutuyoruz çünkü Firestore'a kayıt başarılı
        }
      }
      
      debugPrint('✅ Profil başarıyla güncellendi: ${currentUser.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ Profil güncelleme hatası: $e');
      return false;
    }
  }

  // Profil fotoğrafını güncelle
  Future<String?> updateProfilePhoto(String photoURL) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        debugPrint('❌ Kullanıcı oturum açmamış!');
        return null;
      }
      
      // Önce Firestore'a kaydet
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoURL': photoURL,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Profil fotoğrafı Firestore\'a kaydedildi');
      
      // Firebase Auth'da güncelle (ayrı try-catch bloğunda)
      try {
        await currentUser.updatePhotoURL(photoURL);
        debugPrint('✅ Firebase Auth photoURL güncellendi');
      } catch (e) {
        debugPrint('⚠️ Firebase Auth photoURL güncellenirken hata, ama Firestore güncellendi: $e');
        // Bu hatayı yutuyoruz çünkü Firestore'a kayıt başarılı
      }
      
      return photoURL;
    } catch (e) {
      debugPrint('❌ Profil fotoğrafı güncelleme hatası: $e');
      return null;
    }
  }

  // Kullanıcı parolasını değiştir
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null || currentUser.email == null) {
        debugPrint('❌ Kullanıcı oturum açmamış veya e-posta adresi yok!');
        return false;
      }
      
      // Mevcut parola ile kullanıcıyı doğrula
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      
      // Yeni parolayı ayarla
      await currentUser.updatePassword(newPassword);
      
      debugPrint('✅ Parola başarıyla güncellendi');
      return true;
    } catch (e) {
      debugPrint('❌ Parola değiştirme hatası: $e');
      return false;
    }
  }

  // Kullanıcı hesabını sil
  Future<bool> deleteAccount(String password) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null || currentUser.email == null) {
        debugPrint('❌ Kullanıcı oturum açmamış veya e-posta adresi yok!');
        return false;
      }
      
      // Mevcut parola ile kullanıcıyı doğrula
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      
      // Firestore'dan kullanıcı verilerini sil
      await _firestore.collection('users').doc(currentUser.uid).delete();
      
      // Firebase Auth'dan kullanıcıyı sil
      await currentUser.delete();
      
      debugPrint('✅ Kullanıcı hesabı başarıyla silindi');
      return true;
    } catch (e) {
      debugPrint('❌ Hesap silme hatası: $e');
      return false;
    }
  }
} 