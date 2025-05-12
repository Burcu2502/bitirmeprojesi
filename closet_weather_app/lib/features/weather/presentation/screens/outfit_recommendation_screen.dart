import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/outfit_recommendation_service.dart';
import '../providers/weather_provider.dart';
import '../../../wardrobe/presentation/widgets/clothing_grid_item.dart';

class OutfitRecommendationScreen extends ConsumerStatefulWidget {
  final WeatherModel weather;
  
  const OutfitRecommendationScreen({
    Key? key,
    required this.weather,
  }) : super(key: key);

  @override
  ConsumerState<OutfitRecommendationScreen> createState() => _OutfitRecommendationScreenState();
}

class _OutfitRecommendationScreenState extends ConsumerState<OutfitRecommendationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final OutfitRecommendationService _recommendationService = OutfitRecommendationService();
  
  List<ClothingItemModel> _recommendedOutfit = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Kullanıcının kıyafetlerini getir
      final clothingItems = await _firestoreService.getUserClothingItems(userId);
      
      if (clothingItems.isEmpty) {
        setState(() {
          _errorMessage = 'Dolabınızda kıyafet bulunmamaktadır. Öneri oluşturmak için lütfen kıyafet ekleyin.';
          _isLoading = false;
        });
        return;
      }
      
      // Kullanıcı bilgilerini getir (cilt tonu için)
      final user = await _firestoreService.getUser(userId);
      
      // Kombin önerisi oluştur
      final recommendedOutfit = _recommendationService.recommendOutfitForWeather(
        clothingItems,
        widget.weather,
        skinTone: user?.skinTone,
      );
      
      setState(() {
        _recommendedOutfit = recommendedOutfit;
        _isLoading = false;
        if (recommendedOutfit.isEmpty) {
          _errorMessage = 'Mevcut hava durumu için uygun kıyafet kombinasyonu oluşturulamadı. Lütfen dolabınıza daha fazla kıyafet ekleyin.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kombin önerisi oluşturulurken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveOutfit() async {
    if (_recommendedOutfit.isEmpty) return;
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Kombin nesnesi oluştur
      final outfit = OutfitModel(
        id: '', // Firestore eklerken atanacak
        userId: userId,
        name: 'Hava Durumu Önerisi: ${widget.weather.temperature.toStringAsFixed(0)}°C, ${widget.weather.description}',
        description: 'Otomatik oluşturulmuş kombin',
        clothingItemIds: _recommendedOutfit.map((item) => item.id).toList(),
        seasons: _getOutfitSeasons(),
        weatherConditions: [widget.weather.condition],
        occasion: Occasion.casual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Firestore'a kaydet
      await _firestoreService.addOutfit(outfit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kombin kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kombin kaydedilemedi: $e')),
        );
      }
    }
  }
  
  List<Season> _getOutfitSeasons() {
    final seasons = <Season>{};
    for (final item in _recommendedOutfit) {
      seasons.addAll(item.seasons);
    }
    return seasons.toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hava Durumuna Göre Kombin'),
        actions: [
          if (_recommendedOutfit.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Kombini Kaydet',
              onPressed: _saveOutfit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 64,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRecommendations,
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hava durumu bilgisi
                      _buildWeatherCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Kombin başlığı
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Bugün İçin Önerilen Kombin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Kıyafet önerileri
                      _buildClothingRecommendations(),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Hava durumu ikonu
          Image.network(
            'https://openweathermap.org/img/wn/${widget.weather.icon}@2x.png',
            width: 64,
            height: 64,
          ),
          const SizedBox(width: 16),
          // Hava durumu bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.weather.temperature.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.weather.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hissedilen: ${widget.weather.feelsLike.toStringAsFixed(0)}°C, ${widget.weather.location}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClothingRecommendations() {
    if (_recommendedOutfit.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Mevcut hava durumu için uygun kıyafet kombinasyonu oluşturulamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendedOutfit.length,
      itemBuilder: (context, index) {
        final item = _recommendedOutfit[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_not_supported),
                  ),
            title: Text(item.name),
            subtitle: Text(_getClothingTypeText(item.type)),
          ),
        );
      },
    );
  }
  
  String _getClothingTypeText(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'T-Shirt';
      case ClothingType.shirt:
        return 'Gömlek';
      case ClothingType.blouse:
        return 'Bluz';
      case ClothingType.sweater:
        return 'Kazak';
      case ClothingType.jacket:
        return 'Ceket';
      case ClothingType.coat:
        return 'Mont/Kaban';
      case ClothingType.jeans:
        return 'Kot Pantolon';
      case ClothingType.pants:
        return 'Pantolon';
      case ClothingType.shorts:
        return 'Şort';
      case ClothingType.skirt:
        return 'Etek';
      case ClothingType.dress:
        return 'Elbise';
      case ClothingType.shoes:
        return 'Ayakkabı';
      case ClothingType.boots:
        return 'Bot';
      case ClothingType.accessory:
        return 'Aksesuar';
      case ClothingType.hat:
        return 'Şapka';
      case ClothingType.scarf:
        return 'Atkı/Eşarp';
      case ClothingType.other:
        return 'Diğer';
    }
  }
} 