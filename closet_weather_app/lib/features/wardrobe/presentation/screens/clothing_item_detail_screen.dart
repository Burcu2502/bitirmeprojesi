import 'package:flutter/material.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../shared/widgets/custom_button.dart';

class ClothingItemDetailScreen extends StatelessWidget {
  final ClothingItemModel item;
  
  const ClothingItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Düzenleme özelliği yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              Hero(
                tag: 'clothing_item_${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder(context);
                          },
                        )
                      : _buildImagePlaceholder(context),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Basic info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.brand != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.brand!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _clothingTypeToString(item.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Colors section
              if (item.colors.isNotEmpty) ...[
                _buildSectionTitle(context, 'Renkler'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: item.colors.map((color) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _colorFromHex(color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          color.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Seasons section
              if (item.seasons.isNotEmpty) ...[
                _buildSectionTitle(context, 'Uygun Mevsimler'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.seasons.map((season) {
                    return Chip(
                      label: Text(_seasonToString(season)),
                      avatar: Icon(_getSeasonIcon(season), size: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Details section
              _buildSectionTitle(context, 'Detaylar'),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (item.material != null)
                        _buildDetailRow(
                          context, 
                          'Materyal', 
                          item.material!,
                          Icons.layers,
                        ),
                      if (item.metadata != null && item.metadata!.isNotEmpty) ...[
                        for (var entry in item.metadata!.entries)
                          _buildDetailRow(
                            context,
                            entry.key,
                            entry.value.toString(),
                            Icons.info_outline,
                          ),
                      ],
                      _buildDetailRow(
                        context,
                        'Eklenme Tarihi',
                        _formatDate(item.createdAt),
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Outfit Ekle',
                      icon: Icons.style,
                      onPressed: () {
                        // TODO: Add to outfit functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Outfit ekleme özelliği yakında eklenecek')),
                        );
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
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          _getClothingTypeIcon(item.type),
          size: 100,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kıyafeti Sil'),
        content: Text('${item.name} adlı kıyafeti silmek istediğinize emin misiniz?'),
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
                const SnackBar(content: Text('Kıyafet silindi')),
              );
            },
            child: const Text('Sil'),
          ),
        ],
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
} 