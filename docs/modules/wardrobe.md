# 👕 Dolap Yönetimi Modülü

## 📝 Genel Bakış

Dolap yönetimi modülü, kullanıcıların kıyafetlerini dijital ortamda yönetmelerini sağlar. Kıyafet ekleme, düzenleme, kategorilendirme ve arama gibi temel işlevleri sunar.

## 🔧 Teknik Detaylar

### Kullanılan Teknolojiler
- Firebase Firestore (veri depolama)
- Firebase Storage (görsel depolama)
- TensorFlow Lite (kıyafet tanıma)
- Image Processing (renk analizi)

### Veri Modelleri

#### 1. Kıyafet Modeli
```dart
// lib/features/wardrobe/models/clothing_item.dart
class ClothingItem {
  final String id;
  final String userId;
  final String name;
  final ClothingType type;
  final List<String> colors;
  final Season season;
  final String imageUrl;
  final Map<String, dynamic> metadata;

  // Firestore Serializasyon
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type.toString(),
    'colors': colors,
    'season': season.toString(),
    'imageUrl': imageUrl,
    'metadata': metadata,
  };
}
```

### Temel İşlevler

#### 1. Kıyafet Ekleme
```dart
// lib/features/wardrobe/services/wardrobe_service.dart
class WardrobeService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImageProcessor _imageProcessor;

  Future<String> addClothing(File image, ClothingData data) async {
    // 1. Görüntü işleme
    final processedImage = await _imageProcessor.processImage(image);
    final colors = await _imageProcessor.extractColors(processedImage);

    // 2. Firebase Storage'a yükleme
    final storageRef = _storage.ref().child('clothes/${uuid.v4()}.jpg');
    await storageRef.putFile(processedImage);
    final imageUrl = await storageRef.getDownloadURL();

    // 3. Firestore'a kaydetme
    final clothing = ClothingItem(
      userId: getCurrentUserId(),
      name: data.name,
      type: data.type,
      colors: colors,
      season: data.season,
      imageUrl: imageUrl,
    );

    final doc = await _firestore.collection('clothes').add(clothing.toJson());
    return doc.id;
  }
}
```

#### 2. Kıyafet Listeleme ve Filtreleme
```dart
// lib/features/wardrobe/repositories/wardrobe_repository.dart
class WardrobeRepository {
  Future<List<ClothingItem>> getClothes({
    ClothingType? type,
    Season? season,
    List<String>? colors,
  }) async {
    var query = _firestore
        .collection('clothes')
        .where('userId', isEqualTo: getCurrentUserId());

    if (type != null) {
      query = query.where('type', isEqualTo: type.toString());
    }
    if (season != null) {
      query = query.where('season', isEqualTo: season.toString());
    }
    if (colors != null && colors.isNotEmpty) {
      query = query.where('colors', arrayContainsAny: colors);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ClothingItem.fromFirestore(doc))
        .toList();
  }
}
```

## 📱 Ekran Görüntüleri ve Akış

### Dolap Ana Ekranı
<img src="../assets/screenshots/wardrobe_main.png" width="300">

1. Kategorilere göre filtreleme
2. Grid görünümünde kıyafetler
3. Hızlı arama özelliği
4. Kıyafet ekleme butonu

### Kıyafet Ekleme Ekranı
<img src="../assets/screenshots/add_clothing.png" width="300">

1. Fotoğraf çekme/seçme
2. Otomatik kategori tespiti
3. Renk analizi
4. Detay bilgileri girişi

## 🎨 Renk Analizi ve Kategori Tespiti

```dart
// lib/features/wardrobe/services/image_processor.dart
class ImageProcessor {
  final Interpreter _classifier;
  final ColorAnalyzer _colorAnalyzer;

  Future<ClothingType> detectClothingType(File image) async {
    final processedImage = await _preprocessImage(image);
    final output = await _classifier.run(processedImage);
    return _mapOutputToType(output);
  }

  Future<List<String>> extractDominantColors(File image) async {
    final pixels = await _colorAnalyzer.getPixels(image);
    final clusters = await _colorAnalyzer.kMeansClustering(pixels, k: 3);
    return clusters.map((c) => c.toHexString()).toList();
  }
}
```

## 🔄 State Management

```dart
// lib/features/wardrobe/providers/wardrobe_provider.dart
final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>((ref) {
  return WardrobeNotifier(ref.read(wardrobeRepositoryProvider));
});

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final WardrobeRepository _repository;

  Future<void> loadWardrobe({
    ClothingType? type,
    Season? season,
    List<String>? colors,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final clothes = await _repository.getClothes(
        type: type,
        season: season,
        colors: colors,
      );
      state = state.copyWith(
        clothes: clothes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
```

## 🚀 Kullanım Örneği

```dart
class WardrobeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeState = ref.watch(wardrobeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dolabım'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddClothingDialog(context),
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final clothing = wardrobeState.clothes[index];
          return ClothingCard(clothing: clothing);
        },
      ),
    );
  }
}
``` 