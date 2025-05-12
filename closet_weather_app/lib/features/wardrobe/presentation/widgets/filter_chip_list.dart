import 'package:flutter/material.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../providers/wardrobe_provider.dart';

class FilterChipList extends StatelessWidget {
  final ClothingFilter filter;
  final Function(ClothingFilter) onFilterChanged;
  
  const FilterChipList({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tip filtreleri
          if (filter.types != null && filter.types!.isNotEmpty)
            ...filter.types!.map((type) => _buildFilterChip(
              label: _getTypeName(type),
              onDeleted: () {
                final newTypes = filter.types!.where((t) => t != type).toList();
                onFilterChanged(ClothingFilter(
                  types: newTypes.isEmpty ? null : newTypes,
                  seasons: filter.seasons,
                  colors: filter.colors,
                  searchQuery: filter.searchQuery,
                ));
              },
            )),
            
          // Mevsim filtreleri
          if (filter.seasons != null && filter.seasons!.isNotEmpty)
            ...filter.seasons!.map((season) => _buildFilterChip(
              label: _getSeasonName(season),
              onDeleted: () {
                final newSeasons = filter.seasons!.where((s) => s != season).toList();
                onFilterChanged(ClothingFilter(
                  types: filter.types,
                  seasons: newSeasons.isEmpty ? null : newSeasons,
                  colors: filter.colors,
                  searchQuery: filter.searchQuery,
                ));
              },
            )),
          
          // Renk filtreleri
          if (filter.colors != null && filter.colors!.isNotEmpty)
            ...filter.colors!.map((color) => _buildFilterChip(
              label: color,
              onDeleted: () {
                final newColors = filter.colors!.where((c) => c != color).toList();
                onFilterChanged(ClothingFilter(
                  types: filter.types,
                  seasons: filter.seasons,
                  colors: newColors.isEmpty ? null : newColors,
                  searchQuery: filter.searchQuery,
                ));
              },
              color: _hexToColor(color),
            )),
            
          // Arama sorgusu filtresi
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty)
            _buildFilterChip(
              label: '"${filter.searchQuery}"',
              onDeleted: () {
                onFilterChanged(ClothingFilter(
                  types: filter.types,
                  seasons: filter.seasons,
                  colors: filter.colors,
                ));
              },
              icon: Icons.search,
            ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    Color? color,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) 
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, size: 16),
              ),
            if (color != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Text(label),
          ],
        ),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
        ),
        onDeleted: onDeleted,
      ),
    );
  }
  
  String _getTypeName(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'Tişört';
      case ClothingType.pants:
        return 'Pantolon';
      case ClothingType.jacket:
        return 'Ceket';
      default:
        return type.toString().split('.').last;
    }
  }
  
  String _getSeasonName(Season season) {
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
      default:
        return season.toString().split('.').last;
    }
  }
  
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
} 