import 'package:flutter/material.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../shared/widgets/custom_button.dart';

class OutfitDetailScreen extends StatelessWidget {
  final OutfitModel outfit;
  final List<ClothingItemModel> clothingItems;
  
  const OutfitDetailScreen({
    super.key,
    required this.outfit,
    required this.clothingItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(outfit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit outfit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Düzenleme özelliği yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit details
            _buildOutfitDetails(context),
            
            const SizedBox(height: 16),
            
            // Clothing items list
            Expanded(
              child: _buildClothingItemsList(context),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Mevsim Kontrol Et',
                    icon: Icons.wb_sunny,
                    onPressed: () {
                      _showSeasonCompatibilityDialog(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    label: 'Sil',
                    icon: Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () {
                      _showDeleteConfirmationDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitDetails(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            if (outfit.description != null && outfit.description!.isNotEmpty) ...[
              Text(
                'Açıklama',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                outfit.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Seasons and weather conditions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sezonlar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: outfit.seasons.map((season) {
                          return Chip(
                            label: Text(_seasonToString(season)),
                            avatar: Icon(_getSeasonIcon(season), size: 16),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                if (outfit.weatherConditions.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hava Koşulları',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: outfit.weatherConditions.map((condition) {
                            return Chip(
                              label: Text(_weatherConditionToString(condition)),
                              avatar: Icon(_getWeatherConditionIcon(condition), size: 16),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Occasion
            if (outfit.occasion != null) ...[
              Text(
                'Durum',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(_occasionToString(outfit.occasion)),
                avatar: const Icon(Icons.event, size: 16),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClothingItemsList(BuildContext context) {
    if (clothingItems.isEmpty) {
      return const Center(
        child: Text('Bu kombinde hiç kıyafet bulunmuyor.'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kombindeki Kıyafetler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: clothingItems.length,
            itemBuilder: (context, index) {
              final item = clothingItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  _getClothingTypeIcon(item.type),
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: Icon(
                            _getClothingTypeIcon(item.type),
                            color: Colors.grey.shade600,
                          ),
                        ),
                  title: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    item.brand ?? _clothingTypeToString(item.type),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: item.colors.isNotEmpty
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _colorFromHex(item.colors.first),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        )
                      : null,
                  onTap: () {
                    // TODO: Navigate to clothing item detail
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} detayları yakında gösterilecek')),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSeasonCompatibilityDialog(BuildContext context) {
    final currentSeason = _getCurrentSeason();
    final isCompatible = outfit.seasons.contains(currentSeason);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isCompatible ? 'Mevsim Uyumlu!' : 'Mevsim Uyumlu Değil',
          style: TextStyle(
            color: isCompatible ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şu anki mevsim: ${_seasonToString(currentSeason)}'),
            const SizedBox(height: 8),
            Text(
              isCompatible
                  ? 'Bu kombin şu anki mevsim için uygundur.'
                  : 'Bu kombin şu anki mevsim için uygun değildir. Kombinin uygun olduğu mevsimler:',
            ),
            if (!isCompatible) ...[
              const SizedBox(height: 8),
              ...outfit.seasons.map((season) => Text('• ${_seasonToString(season)}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kombini Sil'),
        content: Text('${outfit.name} adlı kombini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Navigate back after delete
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kombin silindi')),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Season _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;
    
    if (month >= 3 && month <= 5) {
      return Season.spring;
    } else if (month >= 6 && month <= 8) {
      return Season.summer;
    } else if (month >= 9 && month <= 11) {
      return Season.fall;
    } else {
      return Season.winter;
    }
  }

  IconData _getSeasonIcon(Season season) {
    switch (season) {
      case Season.spring:
        return Icons.eco;
      case Season.summer:
        return Icons.wb_sunny;
      case Season.fall:
        return Icons.landscape;
      case Season.winter:
        return Icons.ac_unit;
      case Season.all:
        return Icons.all_inclusive;
    }
  }

  String _seasonToString(Season season) {
    switch (season) {
      case Season.spring:
        return 'İlkbahar';
      case Season.summer:
        return 'Yaz';
      case Season.fall:
        return 'Sonbahar';
      case Season.winter:
        return 'Kış';
      case Season.all:
        return 'Tüm Mevsimler';
    }
  }
  
  IconData _getWeatherConditionIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.partlyCloudy:
        return Icons.wb_cloudy;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.stormy:
        return Icons.flash_on;
      case WeatherCondition.snowy:
        return Icons.ac_unit;
      case WeatherCondition.windy:
        return Icons.air;
      case WeatherCondition.foggy:
        return Icons.cloud;
      case WeatherCondition.hot:
        return Icons.whatshot;
      case WeatherCondition.cold:
        return Icons.ac_unit;
      case WeatherCondition.mild:
        return Icons.wb_twilight;
      case WeatherCondition.any:
        return Icons.all_inclusive;
    }
  }

  String _weatherConditionToString(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Güneşli';
      case WeatherCondition.partlyCloudy:
        return 'Parçalı Bulutlu';
      case WeatherCondition.cloudy:
        return 'Bulutlu';
      case WeatherCondition.rainy:
        return 'Yağmurlu';
      case WeatherCondition.stormy:
        return 'Fırtınalı';
      case WeatherCondition.snowy:
        return 'Karlı';
      case WeatherCondition.windy:
        return 'Rüzgarlı';
      case WeatherCondition.foggy:
        return 'Sisli';
      case WeatherCondition.hot:
        return 'Sıcak';
      case WeatherCondition.cold:
        return 'Soğuk';
      case WeatherCondition.mild:
        return 'Ilıman';
      case WeatherCondition.any:
        return 'Tüm Koşullar';
    }
  }
  
  String _occasionToString(Occasion occasion) {
    switch (occasion) {
      case Occasion.casual:
        return 'Günlük';
      case Occasion.formal:
        return 'Resmi';
      case Occasion.business:
        return 'İş';
      case Occasion.sports:
        return 'Spor';
      case Occasion.party:
        return 'Parti';
      case Occasion.beach:
        return 'Plaj';
      case Occasion.home:
        return 'Ev';
      case Occasion.travel:
        return 'Seyahat';
      case Occasion.other:
        return 'Diğer';
    }
  }
  
  IconData _getClothingTypeIcon(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
      case ClothingType.shirt:
      case ClothingType.blouse:
      case ClothingType.sweater:
        return Icons.checkroom;
      case ClothingType.jacket:
      case ClothingType.coat:
        return Icons.layers;
      case ClothingType.jeans:
      case ClothingType.pants:
      case ClothingType.shorts:
      case ClothingType.skirt:
        return Icons.shopping_bag;
      case ClothingType.dress:
        return Icons.accessibility_new;
      case ClothingType.shoes:
      case ClothingType.boots:
        return Icons.snowshoeing;
      case ClothingType.accessory:
      case ClothingType.hat:
      case ClothingType.scarf:
        return Icons.watch;
      case ClothingType.other:
      default:
        return Icons.checkroom;
    }
  }
  
  String _clothingTypeToString(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'Tişört';
      case ClothingType.shirt:
        return 'Gömlek';
      case ClothingType.blouse:
        return 'Bluz';
      case ClothingType.sweater:
        return 'Kazak';
      case ClothingType.jacket:
        return 'Ceket';
      case ClothingType.coat:
        return 'Mont';
      case ClothingType.jeans:
        return 'Kot';
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
        return 'Atkı/Şal';
      case ClothingType.other:
        return 'Diğer';
    }
  }
  
  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
} 