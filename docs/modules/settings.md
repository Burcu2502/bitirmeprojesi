# Ayarlar ve Yapılandırma Dokümantasyonu

## 1. Yapılandırma Seviyeleri

Uygulama yapılandırması dört ana seviyede yönetilmektedir:

1. Uygulama Seviyesi Yapılandırmalar
2. Kullanıcı Tercihleri
3. Modül Spesifik Ayarlar
4. Ekran Bazlı Yapılandırmalar

## 2. Uygulama Seviyesi Yapılandırmalar

### 2.1. Ortam Değişkenleri
```dart
// lib/config/env.dart
class Environment {
  static const apiKey = String.fromEnvironment('OPENWEATHERMAP_API_KEY');
  static const firebaseConfig = String.fromEnvironment('FIREBASE_CONFIG');
  static const mlModelPath = String.fromEnvironment('ML_MODEL_PATH');
}
```

### 2.2. Firebase Yapılandırması
```dart
// lib/config/firebase_options.dart
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "API_KEY",
    authDomain: "PROJECT_ID.firebaseapp.com",
    projectId: "PROJECT_ID",
    storageBucket: "PROJECT_ID.appspot.com",
    messagingSenderId: "SENDER_ID",
    appId: "APP_ID"
  );
}
```

## 3. Kullanıcı Tercihleri Yönetimi

### 3.1. Ana Ayarlar Ekranı
```dart
// lib/features/settings/screens/settings_screen.dart
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Ayarlar')),
      body: ListView(
        children: [
          // Bildirim Yapılandırması
          SwitchListTile(
            title: Text('Günlük Kombin Önerisi'),
            subtitle: Text('Her sabah yeni kombin önerisi al'),
            value: ref.watch(notificationSettingsProvider),
            onChanged: (value) => ref.read(notificationSettingsProvider.notifier).update(value),
          ),
          
          // Konum Yapılandırması
          SwitchListTile(
            title: Text('Otomatik Konum'),
            subtitle: Text('Hava durumu için konum güncelleme'),
            value: ref.watch(locationSettingsProvider),
            onChanged: (value) => ref.read(locationSettingsProvider.notifier).update(value),
          ),
          
          // Tema Yapılandırması
          ListTile(
            title: Text('Tema'),
            subtitle: Text('Açık/Koyu tema seçimi'),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeProvider),
              onChanged: (theme) => ref.read(themeProvider.notifier).setTheme(theme!),
              items: ThemeMode.values.map((theme) => 
                DropdownMenuItem(
                  value: theme,
                  child: Text(theme.toString()),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 4. Modül Spesifik Yapılandırmalar

### 4.1. Dolap Modülü Yapılandırması
```dart
// lib/features/wardrobe/screens/wardrobe_settings_screen.dart
class WardrobeSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Dolap Ayarları')),
      body: ListView(
        children: [
          // Görüntü İşleme Yapılandırması
          ListTile(
            title: Text('Fotoğraf Kalitesi'),
            subtitle: Text('Yüklenen fotoğrafların kalitesi'),
            trailing: DropdownButton<ImageQuality>(
              value: ref.watch(imageQualityProvider),
              onChanged: (quality) => 
                ref.read(imageQualityProvider.notifier).setQuality(quality!),
              items: ImageQuality.values.map((quality) =>
                DropdownMenuItem(
                  value: quality,
                  child: Text(quality.toString()),
                ),
              ).toList(),
            ),
          ),
          
          // Kategorizasyon Yapılandırması
          SwitchListTile(
            title: Text('Detaylı Kategori Görünümü'),
            subtitle: Text('Kategorileri alt kategorilerle göster'),
            value: ref.watch(categoryViewProvider),
            onChanged: (value) => 
              ref.read(categoryViewProvider.notifier).update(value),
          ),
        ],
      ),
    );
  }
}
```

### 4.2. Hava Durumu Modülü Yapılandırması
```dart
// lib/features/weather/screens/weather_settings_screen.dart
class WeatherSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Hava Durumu Ayarları')),
      body: ListView(
        children: [
          // Birim Yapılandırması
          ListTile(
            title: Text('Sıcaklık Birimi'),
            subtitle: Text('Celsius/Fahrenheit'),
            trailing: DropdownButton<TemperatureUnit>(
              value: ref.watch(temperatureUnitProvider),
              onChanged: (unit) => 
                ref.read(temperatureUnitProvider.notifier).setUnit(unit!),
              items: TemperatureUnit.values.map((unit) =>
                DropdownMenuItem(
                  value: unit,
                  child: Text(unit.toString()),
                ),
              ).toList(),
            ),
          ),
          
          // Güncelleme Yapılandırması
          ListTile(
            title: Text('Güncelleme Sıklığı'),
            subtitle: Text('Hava durumu verilerinin güncellenme sıklığı'),
            trailing: DropdownButton<Duration>(
              value: ref.watch(weatherUpdateIntervalProvider),
              onChanged: (interval) => 
                ref.read(weatherUpdateIntervalProvider.notifier).setInterval(interval!),
              items: [
                DropdownMenuItem(
                  value: Duration(minutes: 30),
                  child: Text('30 dakika'),
                ),
                DropdownMenuItem(
                  value: Duration(hours: 1),
                  child: Text('1 saat'),
                ),
                DropdownMenuItem(
                  value: Duration(hours: 3),
                  child: Text('3 saat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.3. Kombin Önerisi Modülü Yapılandırması
```dart
// lib/features/outfit/screens/outfit_settings_screen.dart
class OutfitSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Kombin Ayarları')),
      body: ListView(
        children: [
          // Stil Yapılandırması
          MultiSelectListTile<Style>(
            title: Text('Tercih Edilen Stiller'),
            subtitle: Text('Kombin önerilerinde dikkate alınacak stiller'),
            value: ref.watch(preferredStylesProvider),
            onChanged: (styles) => 
              ref.read(preferredStylesProvider.notifier).setStyles(styles!),
            items: Style.values.map((style) =>
              MultiSelectItem(
                value: style,
                label: style.toString(),
              ),
            ).toList(),
          ),
          
          // Renk Yapılandırması
          ListTile(
            title: Text('Renk Tercihleri'),
            subtitle: Text('Tercih edilen renk kombinasyonları'),
            onTap: () => Navigator.pushNamed(context, '/color-preferences'),
          ),
          
          // Mevsimsel Yapılandırma
          ListTile(
            title: Text('Mevsim Ağırlıkları'),
            subtitle: Text('Mevsimlere göre kıyafet önerisi ağırlıkları'),
            onTap: () => Navigator.pushNamed(context, '/season-weights'),
          ),
        ],
      ),
    );
  }
}
```

## 5. Veri Saklama ve Yönetimi

### 5.1. Ayarların Kalıcı Depolanması
```dart
// lib/features/settings/services/settings_service.dart
class SettingsService {
  final SharedPreferences _prefs;
  
  Future<void> saveSettings(Settings settings) async {
    await _prefs.setString('settings', jsonEncode(settings.toJson()));
  }
  
  Future<Settings> loadSettings() async {
    final json = _prefs.getString('settings');
    return json != null 
      ? Settings.fromJson(jsonDecode(json))
      : Settings.defaults();
  }
}
```

### 5.2. Durum Yönetimi
```dart
// lib/features/settings/providers/settings_provider.dart
final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<Settings> {
  final SettingsService _service;
  
  Future<void> loadSettings() async {
    state = await _service.loadSettings();
  }
  
  Future<void> updateSettings(Settings settings) async {
    await _service.saveSettings(settings);
    state = settings;
  }
}
``` 