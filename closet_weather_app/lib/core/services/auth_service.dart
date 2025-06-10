import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Giriş yapan kullanıcıyı döndürür
  User? get currentUser => _auth.currentUser;
  
  // Kullanıcı değişikliklerini dinler
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email ve şifre ile kayıt
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      debugPrint("🔐 Email/Şifre ile kayıt başlatılıyor: $email");
      
      // Önce kullanıcıyı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("✅ Firebase hesabı oluşturuldu: ${userCredential.user?.uid}");

      // Kullanıcı adını ayarla
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(name);
          debugPrint("✅ Kullanıcı adı güncellendi: $name");
        } catch (e) {
          debugPrint("⚠️ Kullanıcı adı güncellenemedi: $e");
          // Devam et, kritik hata değil
        }

        // Firestore'da kullanıcı profili oluştur
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          photoUrl: null,
          skinTone: null,
          stylePreferences: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        try {
          await _firestoreService.createUser(newUser);
          debugPrint("✅ Kullanıcı profili Firestore'da oluşturuldu");
        } catch (e) {
          debugPrint("⚠️ Firestore'da kullanıcı profili oluşturulamadı: $e");
          // Firebase Auth hesabı zaten oluştuğu için devam et
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint("❌ Kayıt olurken hata: $e");
      
      // Pigeon/register spesifik hatalarını yakala
      final errorString = e.toString();
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type \'List<Object?>\' is not a subtype') ||
          errorString.contains('pigeon')) {
        debugPrint("⚠️ Register sırasında Pigeon hatası yakalandı - Firebase Auth durumunu kontrol ediliyor");
        
        // Firebase Auth durumunu kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı kayıt olmuş: ${currentUser.uid}");
          
          // Firestore'da kullanıcı verisini kontrol et/oluştur (manuel isim ile)
          try {
            await _ensureUserDataExists(currentUser, manualName: name);
          } catch (firestoreError) {
            debugPrint("⚠️ Firestore kontrol hatası (Register Pigeon sonrası): $firestoreError");
          }
          
          // Mock UserCredential oluştur (Pigeon hatası nedeniyle)
          return MockUserCredential(currentUser);
        } else {
          debugPrint("❌ Pigeon hatası ve kullanıcı da kayıt olmamış - gerçek hata");
          throw Exception('Kayıt işlemi başarısız oldu');
        }
      }
      
      throw Exception('Kayıt olurken bir hata oluştu: $e');
    }
  }

  // Email ve şifre ile giriş
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint("🔐 Email/Şifre ile giriş yapılıyor: $email");
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("✅ Firebase Authentication başarılı: ${result.user?.uid}");
      
      // Kullanıcı verilerini Firestore'dan al ve yoksa oluştur
      if (result.user != null) {
        try {
          await _ensureUserDataExists(result.user!);
        } catch (e) {
          debugPrint("⚠️ Kullanıcı verileri kontrol edilirken hata: $e");
          // Bu hatayı yut, kritik değil
        }
      }
      
      return result;
    } catch (e) {
      debugPrint("❌ Email/şifre ile giriş yaparken hata: $e");
      
      // Pigeon/login spesifik hatalarını yakala
      final errorString = e.toString();
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type \'List<Object?>\' is not a subtype') ||
          errorString.contains('pigeon')) {
        debugPrint("⚠️ Login sırasında Pigeon hatası yakalandı - Firebase Auth durumunu kontrol ediliyor");
        
        // Firebase Auth durumunu kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı giriş yapmış: ${currentUser.uid}");
          
          // Firestore'da kullanıcı verisini kontrol et/oluştur
          try {
            await _ensureUserDataExists(currentUser);
          } catch (firestoreError) {
            debugPrint("⚠️ Firestore kontrol hatası (Login Pigeon sonrası): $firestoreError");
          }
          
          // Mock UserCredential oluştur (Pigeon hatası nedeniyle)
          return MockUserCredential(currentUser);
        } else {
          debugPrint("❌ Pigeon hatası ve kullanıcı da giriş yapmamış - gerçek hata");
          throw Exception('Kullanıcı adı veya şifre yanlış');
        }
      }
      
      throw Exception('Giriş yaparken bir hata oluştu: $e');
    }
  }

  // Google ile giriş
  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint("🔐 Google ile giriş başlatılıyor");
      
      // Google ile giriş işlemi - basitleştirilmiş
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // Google Play Services hatası için basit konfigürasyon
        scopes: ['email', 'profile'],
      );
      
      // Önce mevcut oturumu temizle
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint("❌ Google hesabı seçilmedi veya işlem iptal edildi");
        throw Exception('Google giriş işlemi iptal edildi');
      }
      
      debugPrint("✅ Google hesabı seçildi: ${googleUser.email}");
      
      // Google ile kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint("✅ Google authentication başarılı");
      
      // Firebase ile giriş için kimlik bilgisi oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint("🔄 Firebase credential oluşturuldu, Firebase'e giriş yapılıyor...");
      
      // Firebase ile giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint("✅ Firebase giriş başarılı: ${userCredential.user?.uid}");
          
      // Kullanıcı verilerini Firestore'da kontrol et ve oluştur
      if (userCredential.user != null) {
        try {
          final userData = await _firestoreService.getUser(userCredential.user!.uid);
          
          if (userData == null) {
            // Kullanıcı Firestore'da yoksa oluştur (Google displayName ile)
            await _ensureUserDataExists(userCredential.user!, manualName: googleUser.displayName);
            debugPrint("✅ Yeni Google kullanıcısı Firestore'da oluşturuldu");
          }
        } catch (e) {
          debugPrint("⚠️ Firestore kullanıcı kontrol/oluşturma hatası: $e");
          // Firebase Auth başarılı olduğu için devam et
        }
      }
      
      return userCredential;
    } catch (e) {
      debugPrint("❌ Google ile giriş yaparken genel hata: $e");
      
      // Pigeon/Google Sign-In spesifik hatalarını yakala
      final errorString = e.toString();
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type \'List<Object?>\' is not a subtype') ||
          errorString.contains('pigeon')) {
        debugPrint("⚠️ Pigeon hatası yakalandı - Firebase Auth durumunu kontrol ediliyor");
        
        // Firebase Auth durumunu kontrol et
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı giriş yapmış: ${currentUser.uid}");
          
          // Firestore'da kullanıcı verisini kontrol et/oluştur
          try {
            await _ensureUserDataExists(currentUser);
          } catch (firestoreError) {
            debugPrint("⚠️ Firestore kontrol hatası (Pigeon sonrası): $firestoreError");
          }
          
          // Mock UserCredential oluştur (Pigeon hatası nedeniyle)
          return MockUserCredential(currentUser);
        } else {
          debugPrint("❌ Pigeon hatası ve kullanıcı da giriş yapmamış - gerçek hata");
          throw Exception('Google ile giriş başarısız oldu');
        }
      }
      
      // Google Play Services hatası için özel kontrol
      if (errorString.contains('SecurityException') || 
          errorString.contains('Unknown calling package')) {
        debugPrint("⚠️ Google Play Services güvenlik hatası tespit edildi");
        throw Exception('Google Play Services hatası. Lütfen cihazınızın Google Play Services güncel olduğundan emin olun.');
      }
      
      throw Exception('Google ile giriş yaparken bir hata oluştu: $e');
    }
  }

  // Kullanıcı verilerinin Firestore'da var olduğundan emin ol
  Future<void> _ensureUserDataExists(User user, {String? manualName}) async {
    try {
      debugPrint("🔍 Kullanıcı verileri kontrol ediliyor: ${user.uid}");
      
      final userData = await _firestoreService.getUser(user.uid);
      
      if (userData == null) {
        debugPrint("📝 Kullanıcı Firestore'da bulunamadı, oluşturuluyor...");
        
        // İsim önceliği: manualName > user.displayName > 'Kullanıcı'
        String userName = manualName ?? user.displayName ?? 'Kullanıcı';
        debugPrint("📝 Kullanılacak isim: $userName (manualName: $manualName, displayName: ${user.displayName})");
        
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: userName,
          photoUrl: user.photoURL,
          skinTone: null,
          stylePreferences: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestoreService.createUser(newUser);
        debugPrint("✅ Kullanıcı profili Firestore'da oluşturuldu: $userName");
      } else {
        debugPrint("✅ Kullanıcı verileri zaten mevcut: ${userData.name}");
      }
    } catch (e) {
      debugPrint("❌ Kullanıcı veri kontrolü hatası: $e");
      throw e;
    }
  }

  // Çıkış
  Future<void> signOut() async {
    try {
      debugPrint("🔄 Çıkış yapılıyor...");
      await _googleSignIn.signOut(); // Google oturumunu kapat
      await _auth.signOut();
      debugPrint("✅ Çıkış başarılı");
    } catch (e) {
      debugPrint("❌ Çıkış yaparken hata: $e");
      throw Exception('Çıkış yaparken bir hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      debugPrint("🔄 Kullanıcı profili güncelleniyor...");
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
        debugPrint("✅ Kullanıcı profili güncellendi");
      }
    } catch (e) {
      debugPrint("❌ Profil güncellenirken hata: $e");
      throw Exception('Profil güncellenirken bir hata oluştu: $e');
    }
  }

  // Şifre sıfırlama
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint("🔄 Şifre sıfırlama e-postası gönderiliyor: $email");
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("✅ Şifre sıfırlama e-postası gönderildi");
    } catch (e) {
      debugPrint("❌ Şifre sıfırlama e-postası gönderilirken hata: $e");
      throw Exception('Şifre sıfırlama e-postası gönderilirken bir hata oluştu: $e');
    }
  }

  // Kullanıcı verilerini getir
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) {
        debugPrint("⚠️ Kullanıcı oturumu açık değil");
        return null;
      }
      
      debugPrint("🔄 Kullanıcı verileri getiriliyor: ${currentUser!.uid}");
      final userData = await _firestoreService.getUser(currentUser!.uid);
      
      if (userData != null) {
        debugPrint("✅ Kullanıcı verileri başarıyla alındı: ${userData.name}");
      } else {
        debugPrint("⚠️ Kullanıcı verileri Firestore'da bulunamadı");
        // Kullanıcı verisi yoksa oluştur
        await _ensureUserDataExists(currentUser!);
        // Tekrar dene
        return await _firestoreService.getUser(currentUser!.uid);
      }
      
      return userData;
    } catch (e) {
      debugPrint("❌ Kullanıcı verileri alınırken hata: $e");
      return null;
    }
  }
}

// Mock UserCredential sınıfı (Pigeon hatasını aşmak için)
class MockUserCredential implements UserCredential {
  final User _user;
  
  MockUserCredential(this._user);
  
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  
  @override
  AuthCredential? get credential => null;
  
  @override
  User? get user => _user;
} 