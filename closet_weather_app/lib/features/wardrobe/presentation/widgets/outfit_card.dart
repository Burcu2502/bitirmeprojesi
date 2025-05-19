import 'package:flutter/material.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../presentation/screens/outfit_detail_screen.dart';
import 'dart:io';

class OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final List<ClothingItemModel> clothingItems;
  
  const OutfitCard({
    super.key,
    required this.outfit,
    required this.clothingItems,
  });

  @override
  Widget build(BuildContext context) {
    // Kombin için ilgili kıyafet öğelerini bulalım
    final outfitItems = clothingItems
        .where((item) => outfit.clothingItemIds.contains(item.id))
        .toList();
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OutfitDetailScreen(
              outfit: outfit,
              clothingItems: outfitItems,
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit preview
            SizedBox(
              height: 150,
              child: _buildOutfitPreview(outfitItems),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outfit name
                  Text(
                    outfit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Outfit description
                  if (outfit.description != null && outfit.description!.isNotEmpty)
                    Text(
                      outfit.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Seasons and occasion
                  Row(
                    children: [
                      if (outfit.seasons.isNotEmpty) ...[
                        Icon(
                          _getSeasonIcon(outfit.seasons.first),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSeasonsText(outfit.seasons),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      if (outfit.occasion != null) ...[
                        Icon(
                          Icons.event,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _occasionToString(outfit.occasion),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitPreview(List<ClothingItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    // Sadece resimleri olan öğeleri filtreleyelim
    final itemsWithImages = items
        .where((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty)
        .toList();

    if (itemsWithImages.isEmpty) {
      return ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            _getClothingTypeIcon(items.first.type),
            size: 40, 
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // İlk 3 resmi gösterelim
    final displayItems = itemsWithImages.take(3).toList();
    
    return Row(
      children: displayItems.map((item) {
        return Expanded(
          child: _buildItemImage(item),
        );
      }).toList(),
    );
  }

  Widget _buildItemImage(ClothingItemModel item) {
    final String path = item.imageUrl!;
    
    if (path.startsWith('http')) {
      // URL resmi
      return Image.network(
        path,
        fit: BoxFit.cover,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder(item.type);
        },
      );
    } else {
      // Yerel dosya
      final file = File(path.replaceFirst('file://', ''));
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorPlaceholder(item.type);
              },
            );
          } else {
            return _buildImageErrorPlaceholder(item.type);
          }
        },
      );
    }
  }

  Widget _buildImageErrorPlaceholder(ClothingType type) {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          _getClothingTypeIcon(type),
          size: 30,
          color: Colors.grey.shade600,
        ),
      ),
    );
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
        return Icons.calendar_today;
    }
  }

  String _getSeasonsText(List<Season> seasons) {
    if (seasons.length > 2) {
      return 'Çoklu Sezon';
    } else {
      return seasons.map((s) => _seasonToString(s)).join(', ');
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
} 