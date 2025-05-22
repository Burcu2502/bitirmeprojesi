# 🔐 Kimlik Doğrulama Modülü

## 📝 Genel Bakış

Kimlik doğrulama modülü, kullanıcıların uygulamaya güvenli bir şekilde giriş yapmasını ve hesap yönetimini sağlar. Firebase Authentication servisi kullanılarak implementasyon yapılmıştır.

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- Firebase Authentication
- JWT (JSON Web Tokens)
- Secure Storage

### Kod Örnekleri

#### 1. Giriş İşlemi
```dart
// lib/features/auth/services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel.fromFirebase(result.user!);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}
```

#### 2. Kullanıcı Durumu Yönetimi
```dart
// lib/features/auth/providers/auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

## 📱 Ekran Görüntüleri ve Akış

### Giriş Ekranı
<img src="../assets/screenshots/login_flow.png" width="300">

1. Kullanıcı e-posta ve şifresini girer
2. Validasyon kontrolleri yapılır
3. Firebase'e kimlik doğrulama isteği gönderilir
4. Başarılı girişte ana sayfaya yönlendirilir

### Kayıt Ekranı
<img src="../assets/screenshots/register_flow.png" width="300">

1. Kullanıcı bilgilerini doldurur
2. E-posta doğrulama gönderilir
3. Hesap oluşturulur
4. Profil bilgileri Firestore'a kaydedilir

## 🔒 Güvenlik Önlemleri

1. **Şifre Politikası**
   - Minimum 8 karakter
   - En az 1 büyük harf
   - En az 1 sayı
   - En az 1 özel karakter

2. **Token Yönetimi**
   - JWT kullanımı
   - Refresh token mekanizması
   - Token süre kontrolü

3. **Veri Güvenliği**
   - Hassas verilerin şifrelenmesi
   - Secure Storage kullanımı
   - HTTPS zorunluluğu

## 🚀 Kullanım Örneği

```dart
// Örnek kullanım
final authService = AuthService();

try {
  final user = await authService.signIn(
    email: "user@example.com",
    password: "securePassword123"
  );
  
  if (user != null) {
    // Ana sayfaya yönlendir
    navigator.pushReplacement(HomePage());
  }
} catch (e) {
  // Hata mesajını göster
  showErrorDialog(e.toString());
}
``` 