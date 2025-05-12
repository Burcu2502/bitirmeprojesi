# Auth Modülü

Bu modül, uygulamanın kimlik doğrulama (authentication) özelliklerini içerir.

## Özellikler

- Email ve şifre ile kayıt olma
- Email ve şifre ile giriş yapma
- Google hesabı ile giriş yapma
- Şifre sıfırlama

## Entegrasyon Adımları

1. Firebase projesini [Firebase Console](https://console.firebase.google.com/)'dan oluşturun.
2. Authentication servisini etkinleştirin ve email/password ile Google yöntemlerini açın.
3. Projenizin `google-services.json` dosyasını Android için `android/app/` içine, iOS için `GoogleService-Info.plist` dosyasını `ios/Runner/` içine kopyalayın.

## Google Sign-In Yapılandırması

### Android

1. `android/app/build.gradle` dosyasındaki `defaultConfig` bölümünde `applicationId` değerinin Firebase konsolundaki paket adı ile aynı olduğundan emin olun.

### iOS

1. `ios/Runner/Info.plist` dosyasına aşağıdaki kodları ekleyin:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

`REVERSED_CLIENT_ID` değerini `GoogleService-Info.plist` dosyasındaki değerle değiştirin.

## Google Logo Görüntüsü

Giriş ekranında Google logosu gösterilmektedir. Bu logo için `assets/images/google_logo.png` dosyasını eklemelisiniz. 24x24 piksel boyutunda bir PNG dosyası önerilir.

## Kurulum Kontrol Listesi

- [ ] Firebase projesini oluşturun ve yapılandırın
- [ ] Config dosyalarını projenize ekleyin
- [ ] Google Sign-In için platform yapılandırmalarını tamamlayın
- [ ] Google logosunu varlıklar klasörüne ekleyin
- [ ] `flutter pub get` ile paketleri güncelleyin

## Kullanım

Auth modülü Riverpod ile state yönetimi kullanır. Kimlik doğrulama durumunu izlemek için:

```dart
final authState = ref.watch(authProvider);

// Kullanıcı giriş yapmış mı?
if (authState.isAuthenticated) {
  // Giriş yapmış kullanıcı için işlemler
} else {
  // Giriş yapmamış kullanıcı için işlemler
}
``` 