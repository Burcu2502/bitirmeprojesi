# 🌤️ Akıllı Dolap Yönetimi Uygulaması

<div align="center">
  <img src="docs/assets/app_logo.png" alt="App Logo" width="200"/>
  <br>
  <p>
    <b>Hava durumuna göre akıllı kombin önerileri sunan mobil uygulama</b>
  </p>
  <hr>
</div>

## 📱 Uygulama Tanıtımı

Bu uygulama, kullanıcıların kıyafet dolabını dijital ortamda yönetmelerini ve günlük hava durumuna uygun kombin önerileri almalarını sağlar. Makine öğrenmesi ve renk analizi algoritmaları kullanarak kişiselleştirilmiş öneriler sunar.

### 🌟 Öne Çıkan Özellikler

- 🎯 Hava durumuna göre akıllı kombin önerileri
- 📸 Kıyafet tanıma ve kategorilendirme
- 🎨 Renk uyumu analizi
- 🌡️ Gerçek zamanlı hava durumu entegrasyonu
- 👤 Kişiselleştirilmiş kullanıcı deneyimi

## 🏗️ Teknik Mimari

Uygulama, Clean Architecture prensiplerine uygun olarak geliştirilmiş ve MVVM (Model-View-ViewModel) tasarım desenini kullanmaktadır. Detaylı teknik dokümantasyon için:

### 📚 Modül Dokümantasyonları

- [👤 Kimlik Doğrulama Modülü](docs/modules/auth.md)
  * Firebase Authentication entegrasyonu
  * Güvenli oturum yönetimi
  * Kullanıcı profil yönetimi

- [👕 Dolap Yönetimi Modülü](docs/modules/wardrobe.md)
  * Kıyafet kategorilendirme
  * Görüntü işleme ve analiz
  * Dolap organizasyonu

- [🌤️ Hava Durumu Modülü](docs/modules/weather.md)
  * OpenWeatherMap API entegrasyonu
  * Konum bazlı hava durumu
  * 5 günlük tahmin

- [👔 Kombin Önerisi Modülü](docs/modules/outfit.md)
  * ML tabanlı öneri sistemi
  * Renk uyumu analizi
  * Hava durumu uyumluluğu

### 🛠️ Teknoloji Stack'i

- **Frontend**
  * Flutter Framework
  * Dart Programlama Dili
  * Riverpod (State Management)
  * Material Design & Custom Widgets

- **Backend**
  * Firebase Platform
    - Authentication
    - Cloud Firestore
    - Storage
    - ML Kit

- **Makine Öğrenmesi**
  * TensorFlow Lite
  * OpenCV
  * Custom ML Modelleri

## 🚀 Kurulum

1. Gereksinimler:
   ```bash
   flutter --version
   # Flutter 3.19.0
   # Dart 3.3.0
   ```

2. Projeyi klonlayın:
   ```bash
   git clone https://github.com/username/closet-weather-app.git
   cd closet-weather-app
   ```

3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```

4. Firebase yapılandırmasını ekleyin:
   ```bash
   flutterfire configure
   ```

5. `.env` dosyasını oluşturun:
   ```env
   OPENWEATHERMAP_API_KEY=your_api_key
   ```

6. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 📱 Ekran Görüntüleri

<div align="center">
  <img src="docs/assets/screenshots/login.png" width="200" />
  <img src="docs/assets/screenshots/home.png" width="200" /> 
  <img src="docs/assets/screenshots/wardrobe.png" width="200" />
  <img src="docs/assets/screenshots/outfit.png" width="200" />
</div>

## 🔒 Güvenlik

- End-to-end encryption
- Güvenli veri depolama
- API güvenliği
- Input validasyonu

## 📈 Performans

- Lazy loading mekanizmaları
- Önbellek yönetimi
- Görüntü optimizasyonu
- Ağ istekleri optimizasyonu

## 🤝 Katkıda Bulunma

1. Fork'layın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit'leyin (`git commit -m 'feat: Add amazing feature'`)
4. Push'layın (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın. 