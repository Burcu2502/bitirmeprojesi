import 'package:flutter/material.dart';
import '../../../../core/models/clothing_item_model.dart';

class ClothingGridItem extends StatelessWidget {
  final ClothingItemModel item;
  final VoidCallback onTap;

  const ClothingGridItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Renk gösterimi için ana rengi kullanıyoruz
    final primaryColor = item.colors.isNotEmpty 
        ? _hexToColor(item.colors.first) 
        : Colors.grey;

    // Renkler
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Görsel alanı
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(primaryColor),
                      )
                    : _buildPlaceholder(primaryColor),
              ),
            ),
            
            // Bilgi alanı
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // İsim ve marka
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.brand != null)
                          Text(
                            item.brand!,
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    
                    // Renkler ve türler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tip bilgisi
                        Text(
                          _getTypeName(item.type),
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        
                        // Renk göstergeleri
                        Row(
                          children: [
                            for (int i = 0; i < item.colors.length && i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(item.colors[i]),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Varsayılan görsel
  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withOpacity(0.3),
      child: Center(
        child: Icon(
          _getTypeIcon(item.type),
          size: 48,
          color: color,
        ),
      ),
    );
  }

  // Hex renk kodunu Color'a dönüştürme
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Kıyafet tipine göre ikon
  IconData _getTypeIcon(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
      case ClothingType.shirt:
      case ClothingType.blouse:
        return Icons.checkroom;
      case ClothingType.sweater:
        return Icons.waves;
      case ClothingType.jacket:
      case ClothingType.coat:
        return Icons.face_retouching_natural;
      case ClothingType.jeans:
      case ClothingType.pants:
      case ClothingType.shorts:
        return Icons.hiking;
      case ClothingType.skirt:
      case ClothingType.dress:
        return Icons.category;
      case ClothingType.shoes:
      case ClothingType.boots:
        return Icons.shop;
      case ClothingType.accessory:
      case ClothingType.hat:
      case ClothingType.scarf:
        return Icons.watch;
      case ClothingType.other:
      default:
        return Icons.checkroom;
    }
  }

  // Kıyafet tipini metne dönüştürme
  String _getTypeName(ClothingType type) {
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
        return 'Atkı';
      case ClothingType.other:
      default:
        return 'Diğer';
    }
  }
} 