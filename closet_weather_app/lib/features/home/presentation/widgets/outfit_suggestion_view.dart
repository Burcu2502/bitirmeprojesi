import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/services/outfit_recommendation_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../../core/providers/firestore_providers.dart';
import 'dart:io';

class OutfitSuggestionView extends ConsumerStatefulWidget {
  const OutfitSuggestionView({Key? key}) : super(key: key);

  @override
  ConsumerState<OutfitSuggestionView> createState() => _OutfitSuggestionViewState();
}

class _OutfitSuggestionViewState extends ConsumerState<OutfitSuggestionView> {
  final OutfitRecommendationService _recommendationService = OutfitRecommendationService();
  bool _isLoading = false;
  List<ClothingItemModel>? _suggestedOutfit;
  
  @override
  void initState() {
    super.initState();
    // Sayfa yüklendiğinde ilk öneriyi getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateNewOutfit();
    });
  }
  
  Future<void> _generateNewOutfit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Kullanıcının kıyafetlerini al
      final clothingItemsAsync = await ref.read(userClothingItemsProvider.future);
      debugPrint("🧮 Kıyafet sayısı: ${clothingItemsAsync.length}");
      
      // Kıyafet tiplerini say
      final upperCount = clothingItemsAsync.where((item) => 
        item.type == ClothingType.tShirt || 
        item.type == ClothingType.shirt || 
        item.type == ClothingType.blouse || 
        item.type == ClothingType.sweater
      ).length;
      
      final lowerCount = clothingItemsAsync.where((item) => 
        item.type == ClothingType.pants || 
        item.type == ClothingType.jeans || 
        item.type == ClothingType.shorts || 
        item.type == ClothingType.skirt
      ).length;
      
      debugPrint("👚 Üst giyim sayısı: $upperCount");
      debugPrint("👖 Alt giyim sayısı: $lowerCount");
      
      // Hava durumu bilgilerini al
      final weatherState = ref.read(weatherStateProvider);
      final currentWeather = weatherState.currentWeather;
      
      // Kıyafet ve hava durumu varsa öneri oluştur
      if (clothingItemsAsync.isNotEmpty && currentWeather != null) {
        final suggestions = _recommendationService.recommendOutfitForWeather(
          clothingItemsAsync,
          currentWeather,
        );
        
        debugPrint("👕 Önerilen kombin sayısı: ${suggestions.length}");
        
        if (mounted) {
          setState(() {
            _suggestedOutfit = suggestions;
            _isLoading = false;
          });
        }
      } else {
        debugPrint("⚠️ Kombin oluşturulamadı: Kıyafet veya hava durumu bilgisi yok");
        if (mounted) {
          setState(() {
            _suggestedOutfit = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Kombin önerisi oluşturulurken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final weatherState = ref.watch(weatherStateProvider);
    
    if (!authState.isAuthenticated) {
      return Center(
        child: Text('general.loginRequired'.tr()),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'wardrobe.whatToWearToday'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Hava durumuna göre kombin önerisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'weather.todayWeather'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Hava durumu bilgileri
                if (weatherState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (weatherState.error != null)
                  Text('weather.unavailable'.tr() + ': ${weatherState.error}')
                else if (weatherState.currentWeather != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${weatherState.currentWeather!.temperature}°C, ${weatherState.currentWeather!.description}'),
                      Text(_getWeatherAdvice(weatherState.currentWeather!)),
                    ],
                  )
                else
                  Text('weather.unavailable'.tr()),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'wardrobe.suggestedOutfit'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSuggestedOutfit(context),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateNewOutfit,
                    child: Text('wardrobe.generateNewOutfit'.tr()),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'wardrobe.personalizedSuggestions'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          
          // Kullanıcının kıyafetleriyle dinamik öneriler
          Expanded(
            child: _buildPersonalizedSuggestions(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestedOutfit(BuildContext context) {
    // Eğer önerilmiş bir kombin yoksa, boş bir mesaj göster
    if (_suggestedOutfit == null || _suggestedOutfit!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'wardrobe.noOutfitToCreate'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'wardrobe.addClothingItems'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // Önerilmiş kıyafetleri göster (en fazla 3 tane)
    final outfitItems = _suggestedOutfit!.take(3).toList();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: outfitItems.map((item) {
        IconData icon;
        switch (item.type) {
          case ClothingType.tShirt:
          case ClothingType.shirt:
          case ClothingType.blouse:
          case ClothingType.sweater:
            icon = Icons.checkroom_outlined;
            break;
          case ClothingType.pants:
          case ClothingType.jeans:
          case ClothingType.shorts:
          case ClothingType.skirt:
            icon = Icons.roller_skating_outlined;
            break;
          case ClothingType.jacket:
          case ClothingType.coat:
            icon = Icons.umbrella_outlined;
            break;
          default:
            icon = Icons.checkroom_outlined;
        }
        
        return _buildClothingItem(
          context,
          icon: icon,
          label: _getClothingTypeName(item.type),
          description: item.name,
          imageUrl: item.imageUrl,
        );
      }).toList(),
    );
  }
  
  Widget _buildClothingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    String? imageUrl,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: _getImageProvider(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(
                    icon,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label.tr(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('file://') || path.startsWith('/data/')) {
      // Dosya yolundaki "file://" prefixini kaldır
      final filePath = path.replaceFirst('file://', '');
      return FileImage(File(filePath));
    } else {
      return NetworkImage(path);
    }
  }
  
  Widget _buildPersonalizedSuggestions(BuildContext context) {
    // Kullanıcının tüm kıyafetlerini al
    final clothingItemsAsyncValue = ref.watch(userClothingItemsProvider);
    
    return clothingItemsAsyncValue.when(
      data: (clothingItems) {
        if (clothingItems.isEmpty) {
          return Center(
            child: Text('wardrobe.noClothingItems'.tr()),
          );
        }
        
        // Rastgele kombinler oluştur (gerçek bir uygulamada bu kısmı geliştirmelisin)
        final List<List<ClothingItemModel>> suggestions = [];
        
        // Eldeki kıyafetlerden birkaç farklı kombin oluştur
        for (int i = 0; i < 4; i++) {
          if (clothingItems.length >= 2) {
            suggestions.add(clothingItems.take(2).toList());
          }
        }
        
        if (suggestions.isEmpty) {
          return Center(
            child: Text('wardrobe.notEnoughItems'.tr()),
          );
        }
        
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: suggestion.isNotEmpty && suggestion[0].imageUrl != null
                          ? DecorationImage(
                              image: _getImageProvider(suggestion[0].imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: suggestion.isEmpty || suggestion[0].imageUrl == null
                        ? Center(
                            child: Icon(
                              Icons.checkroom,
                              size: 48,
                              color: Colors.grey[700],
                            ),
                          )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wardrobe.outfit'.tr() + ' ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.map((item) => item.name).join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('wardrobe.errorLoadingItems'.tr() + ': $error'),
      ),
    );
  }
  
  String _getWeatherAdvice(WeatherModel weather) {
    if (weather.isHot) {
      return 'weather.advice.veryHot'.tr();
    } else if (weather.isWarm) {
      return 'weather.advice.hot'.tr();
    } else if (weather.isMild) {
      return 'weather.advice.mild'.tr();
    } else if (weather.isCool) {
      return 'weather.advice.cool'.tr();
    } else if (weather.isCold) {
      return 'weather.advice.cold'.tr();
    }
    
    switch (weather.condition) {
      case WeatherCondition.rainy:
        return 'weather.advice.rainy'.tr();
      case WeatherCondition.stormy:
        return 'weather.advice.stormy'.tr();
      case WeatherCondition.snowy:
        return 'weather.advice.snowy'.tr();
      case WeatherCondition.windy:
        return 'weather.advice.windy'.tr();
      case WeatherCondition.foggy:
        return 'weather.advice.foggy'.tr();
      case WeatherCondition.sunny:
        return 'weather.advice.sunny'.tr();
      default:
        return 'weather.advice.normal'.tr();
    }
  }
  
  String _getClothingTypeName(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'clothing.tShirt';
      case ClothingType.shirt:
        return 'clothing.shirt';
      case ClothingType.blouse:
        return 'clothing.blouse';
      case ClothingType.sweater:
        return 'clothing.sweater';
      case ClothingType.jacket:
        return 'clothing.jacket';
      case ClothingType.coat:
        return 'clothing.coat';
      case ClothingType.jeans:
        return 'clothing.jeans';
      case ClothingType.pants:
        return 'clothing.pants';
      case ClothingType.shorts:
        return 'clothing.shorts';
      case ClothingType.skirt:
        return 'clothing.skirt';
      case ClothingType.dress:
        return 'clothing.dress';
      case ClothingType.shoes:
        return 'clothing.shoes';
      case ClothingType.boots:
        return 'clothing.boots';
      case ClothingType.accessory:
        return 'clothing.accessory';
      case ClothingType.hat:
        return 'clothing.hat';
      case ClothingType.scarf:
        return 'clothing.scarf';
      default:
        return 'clothing.other';
    }
  }
} 