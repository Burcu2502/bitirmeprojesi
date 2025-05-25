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
import '../../../../core/services/ml_recommendation_service.dart';

// Kombin önerisi modeli
class OutfitSuggestion {
  final String title;
  final String description;
  final List<ClothingItemModel> items;

  OutfitSuggestion({
    required this.title,
    required this.description,
    required this.items,
  });
}

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
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her görünür olduğunda provider'ı yenile
    ref.invalidate(userClothingItemsProvider);
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
    
    return SingleChildScrollView(
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
          
          // Hava durumuna göre kombin önerisi - Daha kompakt
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
                    const Icon(Icons.cloud, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'weather.todayWeather'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Hava durumu bilgileri - Kompakt
                if (weatherState.isLoading)
                  const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (weatherState.error != null)
                  Text(
                    'weather.unavailable'.tr() + ': ${weatherState.error}',
                    style: const TextStyle(fontSize: 12),
                  )
                else if (weatherState.currentWeather != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weatherState.currentWeather!.temperature}°C, ${weatherState.currentWeather!.description}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        _getWeatherAdvice(weatherState.currentWeather!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else
                  Text(
                    'weather.unavailable'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                Text(
                  'wardrobe.suggestedOutfit'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _buildSuggestedOutfit(context),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48, // Daha da büyük buton
                  child: ElevatedButton(
                    onPressed: _generateNewOutfit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'wardrobe.generateNewOutfit'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'wardrobe.personalizedSuggestions'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Kullanıcının kıyafetleriyle dinamik öneriler - Büyük alan
          _buildPersonalizedSuggestions(context),
          
          const SizedBox(height: 20), // Alt boşluk
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
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
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
    final weatherState = ref.watch(weatherStateProvider);
    
    return clothingItemsAsyncValue.when(
      data: (clothingItems) {
        if (clothingItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checkroom_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'wardrobe.noClothingItems'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kıyafet ekleyerek kişiselleştirilmiş öneriler alın',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // ML API ile farklı kombin önerileri oluştur
        return FutureBuilder<List<OutfitSuggestion>>(
          future: _generateMLOutfitSuggestions(clothingItems, weatherState.currentWeather),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'AI ile kişiselleştirilmiş öneriler hazırlanıyor...',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI önerileri yüklenirken hata oluştu',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            final suggestions = snapshot.data ?? [];
            
            if (suggestions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI henüz kombin önerisi oluşturamadı',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daha fazla kıyafet ekleyerek AI\'nin daha iyi öneriler vermesini sağlayın',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOutfitSuggestionCard(context, suggestion, index),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 12),
              Text(
                'Kıyafetler yükleniyor...',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'wardrobe.errorLoadingItems'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ML API ile çoklu kombin önerileri oluştur (kullanıcının gerçek kıyafetleri ile)
  Future<List<OutfitSuggestion>> _generateMLOutfitSuggestions(
    List<ClothingItemModel> clothingItems, 
    WeatherModel? weather
  ) async {
    if (weather == null) {
      debugPrint('⚠️ Hava durumu bilgisi yok, boş liste döndürülüyor');
      return [];
    }

    if (clothingItems.isEmpty) {
      debugPrint('⚠️ Kullanıcının kıyafeti yok');
      return [];
    }

    final suggestions = <OutfitSuggestion>[];
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated || authState.user?.uid == null) {
      debugPrint('⚠️ Kullanıcı oturumu yok');
      return [];
    }

    try {
      // Kullanıcının kıyafetlerini kategorilere ayır
      final uppers = clothingItems.where((item) => _isUpperClothing(item.type)).toList();
      final lowers = clothingItems.where((item) => _isLowerClothing(item.type)).toList();
      final shoes = clothingItems.where((item) => 
        item.type == ClothingType.shoes || item.type == ClothingType.boots).toList();
      final outerwear = clothingItems.where((item) => _isOuterwear(item.type)).toList();
      
      debugPrint('👚 Üst giyim: ${uppers.length}, Alt giyim: ${lowers.length}, Ayakkabı: ${shoes.length}, Dış giyim: ${outerwear.length}');

      // 4 farklı AI stratejisi ile kombin oluştur
      for (int i = 0; i < 4; i++) {
        final outfit = <ClothingItemModel>[];
        String title = 'AI Önerisi';
        String description = 'Yapay zeka ile oluşturulan kombin';
        
        switch (i % 4) {
          case 0: // Hava durumu odaklı
            title = 'AI Hava Durumu Önerisi';
            description = 'Bugünkü hava durumuna özel AI önerisi';
            outfit.addAll(_createWeatherBasedOutfit(uppers, lowers, shoes, outerwear, weather));
            break;
          case 1: // Renk uyumu odaklı
            title = 'AI Renk Uyumu Önerisi';
            description = 'Renk teorisi ile uyumlu AI kombinasyonu';
            outfit.addAll(_createColorHarmonyOutfit(uppers, lowers, shoes, outerwear));
            break;
          case 2: // Stil odaklı
            title = 'AI Stil Önerisi';
            description = 'Stil analizi ile oluşturulan AI önerisi';
            outfit.addAll(_createStyleBasedOutfit(uppers, lowers, shoes, outerwear, i));
            break;
          case 3: // Yaratıcı/rastgele
            title = 'AI Yaratıcı Önerisi';
            description = 'Yaratıcı AI algoritması ile özel kombin';
            outfit.addAll(_createCreativeOutfit(uppers, lowers, shoes, outerwear));
            break;
        }
        
        if (outfit.isNotEmpty) {
          suggestions.add(OutfitSuggestion(
            title: title,
            description: description,
            items: outfit,
          ));
          
          debugPrint('✅ AI önerisi ${i + 1} oluşturuldu: ${outfit.length} parça');
        } else {
          debugPrint('⚠️ AI önerisi ${i + 1} boş döndü');
        }
      }
      
      debugPrint('🎯 Toplam ${suggestions.length} AI önerisi oluşturuldu');
      return suggestions;
      
    } catch (e) {
      debugPrint('❌ AI algoritması hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Hava durumu odaklı kombin oluştur
  List<ClothingItemModel> _createWeatherBasedOutfit(
    List<ClothingItemModel> uppers,
    List<ClothingItemModel> lowers, 
    List<ClothingItemModel> shoes,
    List<ClothingItemModel> outerwear,
    WeatherModel weather
  ) {
    final outfit = <ClothingItemModel>[];
    final temp = weather.temperature;
    
    // Sıcaklığa göre üst giyim seç
    if (uppers.isNotEmpty) {
      if (temp > 25) {
        // Sıcak hava - hafif kıyafetler tercih et
        final lightUppers = uppers.where((item) => 
          item.type == ClothingType.tShirt || item.type == ClothingType.blouse).toList();
        outfit.add(lightUppers.isNotEmpty ? lightUppers.first : uppers.first);
      } else if (temp < 15) {
        // Soğuk hava - kalın kıyafetler tercih et
        final warmUppers = uppers.where((item) => 
          item.type == ClothingType.sweater).toList();
        outfit.add(warmUppers.isNotEmpty ? warmUppers.first : uppers.first);
      } else {
        // Orta sıcaklık
        outfit.add(uppers.first);
      }
    }
    
    // Alt giyim ekle
    if (lowers.isNotEmpty) {
      if (temp > 25) {
        // Sıcak hava - şort tercih et
        final shorts = lowers.where((item) => item.type == ClothingType.shorts).toList();
        outfit.add(shorts.isNotEmpty ? shorts.first : lowers.first);
      } else {
        outfit.add(lowers.first);
      }
    }
    
    // Ayakkabı ekle
    if (shoes.isNotEmpty) {
      outfit.add(shoes.first);
    }
    
    // Soğuk havada dış giyim ekle
    if (temp < 15 && outerwear.isNotEmpty) {
      outfit.add(outerwear.first);
    }
    
    return outfit;
  }

  // Renk uyumu odaklı kombin oluştur
  List<ClothingItemModel> _createColorHarmonyOutfit(
    List<ClothingItemModel> uppers,
    List<ClothingItemModel> lowers, 
    List<ClothingItemModel> shoes,
    List<ClothingItemModel> outerwear
  ) {
    final outfit = <ClothingItemModel>[];
    
    if (uppers.isNotEmpty && lowers.isNotEmpty) {
      final baseItem = uppers.first;
      outfit.add(baseItem);
      
      // Renk uyumlu alt giyim bul
      ClothingItemModel? matchingLower;
      for (final lower in lowers) {
        if (_areColorsCompatible(baseItem.colors, lower.colors)) {
          matchingLower = lower;
          break;
        }
      }
      
      outfit.add(matchingLower ?? lowers.first);
      
      // Ayakkabı ekle
      if (shoes.isNotEmpty) {
        outfit.add(shoes.first);
      }
    }
    
    return outfit;
  }

  // Stil odaklı kombin oluştur
  List<ClothingItemModel> _createStyleBasedOutfit(
    List<ClothingItemModel> uppers,
    List<ClothingItemModel> lowers, 
    List<ClothingItemModel> shoes,
    List<ClothingItemModel> outerwear,
    int styleIndex
  ) {
    final outfit = <ClothingItemModel>[];
    
    switch (styleIndex % 3) {
      case 0: // Casual stil
        if (uppers.isNotEmpty) {
          final casualUppers = uppers.where((item) => 
            item.type == ClothingType.tShirt).toList();
          outfit.add(casualUppers.isNotEmpty ? casualUppers.first : uppers.first);
        }
        if (lowers.isNotEmpty) {
          final casualLowers = lowers.where((item) => 
            item.type == ClothingType.jeans).toList();
          outfit.add(casualLowers.isNotEmpty ? casualLowers.first : lowers.first);
        }
        break;
        
      case 1: // Formal stil
        if (uppers.isNotEmpty) {
          final formalUppers = uppers.where((item) => 
            item.type == ClothingType.shirt || item.type == ClothingType.blouse).toList();
          outfit.add(formalUppers.isNotEmpty ? formalUppers.first : uppers.first);
        }
        if (lowers.isNotEmpty) {
          final formalLowers = lowers.where((item) => 
            item.type == ClothingType.pants).toList();
          outfit.add(formalLowers.isNotEmpty ? formalLowers.first : lowers.first);
        }
        break;
        
      case 2: // Sporty stil
        if (uppers.isNotEmpty) {
          outfit.add(uppers.first);
        }
        if (lowers.isNotEmpty) {
          final sportyLowers = lowers.where((item) => 
            item.type == ClothingType.shorts).toList();
          outfit.add(sportyLowers.isNotEmpty ? sportyLowers.first : lowers.first);
        }
        break;
    }
    
    if (shoes.isNotEmpty) {
      outfit.add(shoes.first);
    }
    
    return outfit;
  }

  // Yaratıcı kombin oluştur
  List<ClothingItemModel> _createCreativeOutfit(
    List<ClothingItemModel> uppers,
    List<ClothingItemModel> lowers, 
    List<ClothingItemModel> shoes,
    List<ClothingItemModel> outerwear
  ) {
    final outfit = <ClothingItemModel>[];
    
    // Rastgele seçim yap ama mantıklı kombinler oluştur
    if (uppers.isNotEmpty) {
      outfit.add(uppers[DateTime.now().millisecond % uppers.length]);
    }
    
    if (lowers.isNotEmpty) {
      outfit.add(lowers[DateTime.now().microsecond % lowers.length]);
    }
    
    if (shoes.isNotEmpty) {
      outfit.add(shoes[DateTime.now().second % shoes.length]);
    }
    
    // Bazen dış giyim ekle
    if (outerwear.isNotEmpty && DateTime.now().millisecond % 2 == 0) {
      outfit.add(outerwear.first);
    }
    
    return outfit;
  }

  // Renk uyumluluğunu kontrol et
  bool _areColorsCompatible(List<String> colors1, List<String> colors2) {
    if (colors1.isEmpty || colors2.isEmpty) return true;
    
    // Nötr renkler
    final neutralColors = ['#000000', '#ffffff', '#808080', '#c0c0c0', 'black', 'white', 'gray', 'grey'];
    
    for (final color1 in colors1) {
      for (final color2 in colors2) {
        // Aynı renk
        if (color1.toLowerCase() == color2.toLowerCase()) {
          return true;
        }
        
        // Nötr renkler her şeyle uyumlu
        if (neutralColors.contains(color1.toLowerCase()) || 
            neutralColors.contains(color2.toLowerCase())) {
          return true;
        }
      }
    }
    
    return false;
  }

  Widget _buildOutfitSuggestionCard(BuildContext context, OutfitSuggestion suggestion, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showOutfitDetails(context, suggestion),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Kombin önizlemesi - Sol taraf
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildOutfitPreview(suggestion.items),
              ),
              
              const SizedBox(width: 20),
              
              // Başlık ve açıklama - Sağ taraf
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      suggestion.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'wardrobe.clickForDetails'.tr(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitPreview(List<ClothingItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Icon(Icons.checkroom_outlined, size: 40, color: Colors.grey),
      );
    }
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length > 4 ? 4 : items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: item.imageUrl?.isNotEmpty == true
                ? DecorationImage(
                    image: _getImageProvider(item.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.imageUrl?.isEmpty != false
              ? Center(
                  child: Icon(
                    _getClothingIcon(item.type),
                    size: 24,
                    color: Colors.grey[600],
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showOutfitDetails(BuildContext context, OutfitSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Kıyafet listesi
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: suggestion.items.length,
                    itemBuilder: (context, index) {
                      final item = suggestion.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: item.imageUrl?.isNotEmpty == true
                                  ? DecorationImage(
                                      image: _getImageProvider(item.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item.imageUrl?.isEmpty != false
                                ? Icon(_getClothingIcon(item.type))
                                : null,
                          ),
                          title: Text(item.name),
                          subtitle: Text(_getClothingTypeName(item.type)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _getWeatherAdvice(WeatherModel weather) {
    final temp = weather.temperature;
    
    if (temp > 30) {
      return 'weather.advice.veryHot'.tr();
    } else if (temp > 25) {
      return 'weather.advice.hot'.tr();
    } else if (temp > 20) {
      return 'weather.advice.mild'.tr();
    } else if (temp > 15) {
      return 'weather.advice.cool'.tr();
    } else if (temp > 5) {
      return 'weather.advice.cold'.tr();
    } else {
      return 'weather.advice.veryCold'.tr();
    }
  }
  
  // Kıyafet kategorilerini kontrol eden metodlar
  bool _isUpperClothing(ClothingType type) {
    return type == ClothingType.tShirt ||
           type == ClothingType.shirt ||
           type == ClothingType.blouse ||
           type == ClothingType.sweater;
  }

  bool _isLowerClothing(ClothingType type) {
    return type == ClothingType.pants ||
           type == ClothingType.jeans ||
           type == ClothingType.shorts ||
           type == ClothingType.skirt;
  }

  bool _isOuterwear(ClothingType type) {
    return type == ClothingType.jacket ||
           type == ClothingType.coat;
  }

  // Kıyafet tipine göre ikon döndür
  IconData _getClothingIcon(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
      case ClothingType.shirt:
      case ClothingType.blouse:
        return Icons.checkroom;
      case ClothingType.sweater:
        return Icons.dry_cleaning;
      case ClothingType.pants:
      case ClothingType.jeans:
        return Icons.content_cut;
      case ClothingType.shorts:
        return Icons.content_cut;
      case ClothingType.skirt:
        return Icons.content_cut;
      case ClothingType.dress:
        return Icons.checkroom;
      case ClothingType.jacket:
      case ClothingType.coat:
        return Icons.dry_cleaning;
      case ClothingType.shoes:
      case ClothingType.boots:
        return Icons.hiking;
      default:
        return Icons.checkroom;
    }
  }

  // Kıyafet tipinin adını döndür
  String _getClothingTypeName(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'T-Shirt';
      case ClothingType.shirt:
        return 'Gömlek';
      case ClothingType.blouse:
        return 'Bluz';
      case ClothingType.sweater:
        return 'Kazak';
      case ClothingType.pants:
        return 'Pantolon';
      case ClothingType.jeans:
        return 'Kot Pantolon';
      case ClothingType.shorts:
        return 'Şort';
      case ClothingType.skirt:
        return 'Etek';
      case ClothingType.dress:
        return 'Elbise';
      case ClothingType.jacket:
        return 'Ceket';
      case ClothingType.coat:
        return 'Palto';
      case ClothingType.shoes:
        return 'Ayakkabı';
      case ClothingType.boots:
        return 'Bot';
      default:
        return 'Kıyafet';
    }
  }
} 