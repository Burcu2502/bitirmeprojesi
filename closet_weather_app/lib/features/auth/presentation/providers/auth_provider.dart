import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';

// Auth state sınıfı
class AuthState {
  final User? user;
  final UserModel? userData;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.userData,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    UserModel? userData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => user != null;
  bool get hasError => errorMessage != null;
}

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  debugPrint('🔄 AuthService oluşturuluyor');
  return AuthService();
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(AuthState()) {
    debugPrint('🔄 AuthNotifier başlatılıyor, authStateChanges dinleniyor');
    // Firebase auth state değişikliklerini dinle
    _authService.authStateChanges.listen((user) {
      debugPrint('🔄 Auth state değişti. User: ${user?.uid}');
      if (user != null) {
        // Kullanıcı girişi başarılı, Firestore verilerini beklemeden state'i güncelle
        state = state.copyWith(
          user: user,
          isLoading: false,
          errorMessage: null,
        );
        
        // Firestore verilerini arka planda almaya çalış (opsiyonel)
        _loadUserDataInBackground(user.uid);
      } else {
        // Kullanıcı çıkış yapmış
        debugPrint('ℹ️ Kullanıcı çıkış yapmış, state sıfırlanıyor');
        state = AuthState();
      }
    });
  }
  
  // Kullanıcı verilerini arka planda yükle
  Future<void> _loadUserDataInBackground(String uid) async {
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData != null && mounted) {
        state = state.copyWith(userData: userData);
        debugPrint('✅ Kullanıcı verisi başarıyla yüklendi: ${userData.name}');
      }
    } catch (e) {
      // Hata olursa sadece log al, UI'da hata gösterme
      debugPrint('⚠️ Kullanıcı verileri arka planda yüklenirken hata: $e');
    }
  }

  // Email ve şifre ile giriş
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    debugPrint('🔄 Email/Şifre ile giriş yapılıyor: $email');
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Auth state listener otomatik olarak state'i güncelleyecek
    } catch (e) {
      debugPrint('❌ Email/Şifre ile giriş hata: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Giriş yapılamadı. Lütfen e-posta ve şifrenizi kontrol edin.',
      );
    }
  }

  // Email ve şifre ile kayıt
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    debugPrint('🔄 Email/Şifre ile kayıt yapılıyor: $email');
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.registerWithEmailAndPassword(email, password, name);
      debugPrint('✅ Email/Şifre ile kayıt başarılı');
      // Auth state listener zaten state'i güncelleyecek
    } catch (e) {
      debugPrint('❌ Email/Şifre ile kayıt hata: $e');
      
      final errorString = e.toString();
      
      // Pigeon hatalarını kontrol et
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type \'List<Object?>\' is not a subtype') ||
          errorString.contains('pigeon')) {
        debugPrint('ℹ️ Kayıt sırasında Pigeon hatası yakalandı - Firebase Auth durumu kontrol ediliyor');
        
        // Firebase Auth durumunu kontrol et
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          debugPrint('✅ Pigeon hatası olmasına rağmen kullanıcı kayıt olmuş: ${currentUser.uid}');
          // State'i başarılı olarak güncelle
          state = state.copyWith(
            user: currentUser,
            isLoading: false,
            errorMessage: null,
          );
          return;
        }
      }
      
      // Diğer hatalar için normal hata mesajı
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Google ile giriş
  Future<void> signInWithGoogle() async {
    debugPrint('🔄 Google ile giriş yapılıyor');
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.signInWithGoogle();
      debugPrint('✅ Google ile giriş başarılı');
      // Auth state listener otomatik olarak state'i güncelleyecek
    } catch (e) {
      debugPrint('❌ Google ile giriş hatası: $e');
      
      final errorString = e.toString();
      
      // Pigeon hatalarını kontrol et
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type \'List<Object?>\' is not a subtype') ||
          errorString.contains('pigeon')) {
        debugPrint('ℹ️ Pigeon hatası yakalandı - Firebase Auth durumu kontrol ediliyor');
        
        // Firebase Auth durumunu kontrol et
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          debugPrint('✅ Pigeon hatası olmasına rağmen kullanıcı giriş yapmış: ${currentUser.uid}');
          // State'i başarılı olarak güncelle
          state = state.copyWith(
            user: currentUser,
            isLoading: false,
            errorMessage: null,
          );
          return;
        }
      }
      
      // İptal durumu kontrol et
      if (errorString.contains('iptal') || errorString.contains('cancel')) {
        debugPrint('ℹ️ Kullanıcı Google girişini iptal etti');
        state = state.copyWith(
          isLoading: false,
          errorMessage: null, // İptal durumunda hata mesajı gösterme
        );
        return;
      }
      
      // Google Play Services hatası için özel mesaj
      if (errorString.contains('Google Play Services') || 
          errorString.contains('SecurityException')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google Play Services hatası. Lütfen cihazınızı güncelleyin.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google ile giriş yapılamadı. Lütfen tekrar deneyin.',
        );
      }
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    debugPrint('🔄 AuthProvider: Çıkış yapılıyor');
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.signOut();
      debugPrint('✅ AuthProvider: Çıkış başarılı');
      // Çıkış işleminde explicit olarak state'i güncelleyelim (listener'ı beklemeden)
      state = AuthState();
    } catch (e) {
      debugPrint('❌ AuthProvider: Çıkış yaparken hata: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      // Hata fırlatalım ki UI katmanı yakalayabilsin
      throw Exception('Çıkış yaparken bir hata oluştu: $e');
    }
  }

  // Şifre sıfırlama
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('🔄 Şifre sıfırlama e-postası gönderiliyor: $email');
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      debugPrint('✅ Şifre sıfırlama e-postası gönderildi');
    } catch (e) {
      debugPrint('❌ Şifre sıfırlama e-postası gönderilirken hata: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  debugPrint('🔄 Auth Provider oluşturuluyor');
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Kullanıcının oturum durumu için provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

// Kullanıcı verilerini izleyen provider
final userDataProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.userData;
}); 