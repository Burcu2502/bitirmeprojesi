import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/models/clothing_item_model.dart';
import '../../presentation/screens/clothing_item_detail_screen.dart';

class ClothingItemCard extends StatelessWidget {
  final ClothingItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const ClothingItemCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kıyafet resmi veya placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: item.imageUrl != null
                    ? _buildImage(item.imageUrl!)
                    : Center(
                        child: Icon(
                          _getIconForClothingType(item.type),
                          size: 48,
                          color: Colors.grey[700],
                        ),
                      ),
              ),
            ),
            
            // Kıyafet detayları
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getClothingTypeName(item.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getSeasonsText(item.seasons),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: item.colors.take(3).map((colorHex) {
                      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    // URL kontrolü
    if (path.startsWith('http')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          path,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Resim yüklenirken hata: $error");
            return Center(
              child: Icon(
                _getIconForClothingType(item.type),
                size: 48,
                color: Colors.grey[700],
              ),
            );
          },
        ),
      );
    } else {
      // Yerel dosya kontrolü
      final file = File(path.replaceFirst('file://', ''));
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData && snapshot.data == true) {
              return Image.file(
                file,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Lokal resim yüklenirken hata: $error");
                  return Center(
                    child: Icon(
                      _getIconForClothingType(item.type),
                      size: 48,
                      color: Colors.grey[700],
                    ),
                  );
                },
              );
            } else {
              return Center(
                child: Icon(
                  _getIconForClothingType(item.type),
                  size: 48,
                  color: Colors.grey[700],
                ),
              );
            }
          },
        ),
      );
    }
  }
  
  IconData _getIconForClothingType(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
      case ClothingType.shirt:
      case ClothingType.blouse:
        return Icons.checkroom_outlined;
      case ClothingType.sweater:
      case ClothingType.jacket:
      case ClothingType.coat:
        return Icons.layers_outlined;
      case ClothingType.jeans:
      case ClothingType.pants:
      case ClothingType.shorts:
      case ClothingType.skirt:
        return Icons.wallet_outlined;
      case ClothingType.dress:
        return Icons.checkroom_outlined;
      case ClothingType.shoes:
      case ClothingType.boots:
        return Icons.snowshoeing_outlined;
      case ClothingType.accessory:
        return Icons.watch_outlined;
      case ClothingType.hat:
        return Icons.face_outlined;
      case ClothingType.scarf:
        return Icons.brightness_low_outlined;
      case ClothingType.other:
      default:
        return Icons.checkroom_outlined;
    }
  }
  
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
  
  String _getSeasonsText(List<Season> seasons) {
    if (seasons.contains(Season.all)) {
      return 'Tüm Sezonlar';
    }
    
    final seasonNames = seasons.map((s) {
      switch (s) {
        case Season.spring:
          return 'İlkb';
        case Season.summer:
          return 'Yaz';
        case Season.fall:
          return 'Sonb';
        case Season.winter:
          return 'Kış';
        case Season.all:
          return 'Tüm';
      }
    }).join(', ');
    
    return seasonNames;
  }
} 