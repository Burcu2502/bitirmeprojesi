# 🌤️ Closet Weather App

Hava durumu ve moda uyumu ile dolap yönetimi yapan akıllı mobil uygulama.

## 🚀 Özellikler

### 🤖 AI Destekli Kombin Önerileri
- **4 Farklı AI Stratejisi**: Hava durumu odaklı, renk uyumu, stil bazlı ve yaratıcı öneriler
- **Kişiselleştirilmiş Öneriler**: Kullanıcının gerçek dolabı ile AI önerileri
- **Hava Durumu Entegrasyonu**: Güncel hava durumuna göre akıllı kombin önerileri

### 👗 Dolap Yönetimi
- **Kıyafet Ekleme**: Fotoğraf çekme veya galeriden seçme
- **Otomatik Renk Analizi**: AI ile renk tespiti
- **Kategori Filtreleme**: Kıyafet tipi, mevsim, renk bazlı filtreleme
- **Arama Özelliği**: Kıyafetlerde hızlı arama

### 🌡️ Hava Durumu
- **Güncel Hava Durumu**: OpenWeatherMap API entegrasyonu
- **5 Günlük Tahmin**: Haftalık hava durumu tahmini
- **Konum Bazlı**: GPS veya manuel konum seçimi

### 👤 Kullanıcı Profili
- **Stil Tercihleri**: Kişisel stil seçenekleri
- **Tema Ayarları**: Açık/koyu tema desteği
- **Çoklu Dil**: Türkçe ve İngilizce desteği

## 🛠️ Teknoloji Stack

### Frontend (Flutter)
- **Flutter 3.0+**: Cross-platform mobil uygulama
- **Riverpod**: State management
- **Easy Localization**: Çoklu dil desteği
- **Material Design 3**: Modern UI/UX

### Backend Services
- **Firebase Auth**: Kullanıcı kimlik doğrulama
- **Cloud Firestore**: NoSQL veritabanı
- **Firebase Storage**: Resim depolama
- **OpenWeatherMap API**: Hava durumu verileri

### AI/ML Services
- **Python Flask API**: Makine öğrenmesi servisi
- **Scikit-learn**: ML algoritmaları
- **NumPy**: Veri işleme
- **Color Theory**: Renk uyumu algoritmaları

## 📱 Ekran Görüntüleri

### Ana Sayfa
- Hava durumu bilgileri
- Günlük kombin önerileri
- Kişiselleştirilmiş AI önerileri

### Dolap Yönetimi
- Kıyafet grid görünümü
- Detaylı kıyafet bilgileri
- Filtreleme ve arama

### AI Kombin Önerileri
- Hava durumu bazlı öneriler
- Renk uyumlu kombinler
- Stil bazlı öneriler

## 🚀 Kurulum

### Gereksinimler
- Flutter 3.0+
- Dart 3.0+
- Python 3.8+ (ML servisi için)
- Firebase projesi

### Flutter Uygulaması
```bash
# Projeyi klonlayın
git clone [repo-url]
cd closet_weather_app

# Bağımlılıkları yükleyin
flutter pub get

# Firebase yapılandırması
# firebase_options.dart dosyasını yapılandırın

# Uygulamayı çalıştırın
flutter run
```

### ML API Servisi
```bash
# ML servis klasörüne gidin
cd ml_service

# Python bağımlılıklarını yükleyin
pip3 install flask flask-cors scikit-learn numpy

# API'yi başlatın
python3 app.py
```

## 🔧 Yapılandırma

### Firebase Kurulumu
1. Firebase Console'da yeni proje oluşturun
2. Authentication, Firestore, Storage servislerini etkinleştirin
3. `firebase_options.dart` dosyasını güncelleyin

### OpenWeatherMap API
1. OpenWeatherMap'te hesap oluşturun
2. API anahtarını alın
3. `weather_service.dart` dosyasında API anahtarını güncelleyin

### ML API Yapılandırması
1. Bilgisayarınızın IP adresini bulun
2. `ml_recommendation_service.dart` dosyasında IP adresini güncelleyin

## 🏗️ Proje Yapısı

```
closet_weather_app/
├── lib/
│   ├── core/                 # Temel servisler ve modeller
│   ├── features/             # Özellik bazlı modüller
│   │   ├── auth/            # Kimlik doğrulama
│   │   ├── home/            # Ana sayfa
│   │   ├── weather/         # Hava durumu
│   │   ├── wardrobe/        # Dolap yönetimi
│   │   └── profile/         # Kullanıcı profili
│   └── shared/              # Paylaşılan bileşenler
├── assets/                  # Resimler ve çeviriler
├── ml_service/              # Python ML API
└── README.md
```

## 🤖 AI Algoritmaları

### 1. Hava Durumu Odaklı Strateji
- Sıcaklık bazlı kıyafet seçimi
- Hava koşullarına göre katman önerileri
- Mevsimsel uygunluk kontrolü

### 2. Renk Uyumu Stratejisi
- Renk teorisi bazlı eşleştirme
- Komplementer ve analog renk uyumu
- Nötr renk kombinasyonları

### 3. Stil Bazlı Strateji
- Casual, formal, sporty stil kategorileri
- Kıyafet tipi bazlı eşleştirme
- Durum bazlı öneriler

### 4. Yaratıcı Strateji
- Rastgele ama uyumlu kombinasyonlar
- Beklenmedik renk eşleştirmeleri
- Trend bazlı öneriler

## 📊 Veri Modelleri

### ClothingItem
- ID, isim, tip, marka
- Renkler, mevsimler, durumlar
- Resim URL'si

### Weather
- Sıcaklık, nem, rüzgar
- Hava durumu açıklaması
- Konum bilgisi

### Outfit
- Kıyafet ID'leri listesi
- Oluşturulma tarihi
- Mevsim ve durum etiketleri

## 🔮 Gelecek Özellikler

- [ ] Sosyal paylaşım
- [ ] Kombin değerlendirme sistemi
- [ ] Trend analizi
- [ ] Mağaza entegrasyonu
- [ ] AR deneme özelliği
- [ ] Akıllı bildirimler

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 👥 Geliştirici

Burcu - Bitirme Projesi

## 🙏 Teşekkürler

- OpenWeatherMap API
- Firebase Services
- Flutter Community
- Material Design Team
