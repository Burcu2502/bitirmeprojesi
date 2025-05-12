import 'package:flutter/material.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../presentation/screens/clothing_item_detail_screen.dart';

class ClothingItemCard extends StatelessWidget {
  final ClothingItemModel item;
  final VoidCallback? onDelete;
  
  const ClothingItemCard({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClothingItemDetailScreen(item: item),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            SizedBox(
              height: 160,
              width: double.infinity,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
            ),
            
            // Item info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type and color indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _clothingTypeToString(item.type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (item.colors.isNotEmpty) ...[
                        for (int i = 0; i < item.colors.length && i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _colorFromHex(item.colors[i]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Item name
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Brand and material
                  if (item.brand != null || item.material != null)
                    Text(
                      [
                        if (item.brand != null) item.brand,
                        if (item.material != null) item.material,
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Seasons
                  if (item.seasons.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getSeasonsText(item.seasons),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  // Actions
                  if (onDelete != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Sil',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          _getClothingTypeIcon(item.type),
          size: 48,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  String _getSeasonsText(List<Season> seasons) {
    if (seasons.length >= 4) {
      return 'Tüm Mevsimler';
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
  
  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
} 