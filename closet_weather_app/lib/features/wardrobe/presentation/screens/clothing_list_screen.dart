import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/clothing_item_card.dart';
import 'add_clothing_item_screen.dart';

class ClothingListScreen extends ConsumerStatefulWidget {
  const ClothingListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClothingListScreen> createState() => _ClothingListScreenState();
}

class _ClothingListScreenState extends ConsumerState<ClothingListScreen> {
  final ClothingFilter _currentFilter = ClothingFilter();
  
  @override
  Widget build(BuildContext context) {
    // Filtrelenmiş kıyafetleri al
    final clothingItemsAsync = ref.watch(filteredClothingItemsProvider(_currentFilter));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('wardrobe.list.myClosets'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: clothingItemsAsync.when(
        data: (clothingItems) {
          if (clothingItems.isEmpty) {
            return Center(
              child: Text('wardrobe.list.emptyCloset'.tr()),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: clothingItems.length,
            itemBuilder: (context, index) {
              final item = clothingItems[index];
              return ClothingItemCard(
                item: item,
                onTap: () {
                  _showClothingItemDetails(context, item);
                },
                onDelete: () {
                  _deleteClothingItem(context, item.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('wardrobe.list.loadingError'.tr(args: [error.toString()])),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNewClothingItem(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _addNewClothingItem(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddClothingItemScreen(),
      ),
    );
    
    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('wardrobe.list.itemAdded'.tr())),
      );
    }
  }
  
  void _showClothingItemDetails(BuildContext context, ClothingItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null) 
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(height: 16),
            Text('wardrobe.list.itemDetails.type'.tr(args: [_getClothingTypeName(item.type)])),
            const SizedBox(height: 8),
            Text('wardrobe.list.itemDetails.seasons'.tr(args: [item.seasons.map((s) => _getSeasonName(s)).join(', ')])),
            if (item.brand != null) ...[
              const SizedBox(height: 8),
              Text('wardrobe.list.itemDetails.brand'.tr(args: [item.brand!])),
            ],
            if (item.material != null) ...[
              const SizedBox(height: 8),
              Text('wardrobe.list.itemDetails.material'.tr(args: [item.material!])),
            ],
            const SizedBox(height: 8),
            Text('wardrobe.list.itemDetails.colors'.tr()),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: item.colors.map((colorHex) {
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                return Container(
                  width: 30,
                  height: 30,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('wardrobe.list.close'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editClothingItem(context, item);
            },
            child: Text('wardrobe.list.edit'.tr()),
          ),
        ],
      ),
    );
  }
  
  void _editClothingItem(BuildContext context, ClothingItemModel item) {
    // TODO: Düzenleme ekranına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('wardrobe.list.edit.comingSoon'.tr())),
    );
  }
  
  Future<void> _deleteClothingItem(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('wardrobe.list.delete.title'.tr()),
        content: Text('wardrobe.list.delete.message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('wardrobe.list.delete.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('wardrobe.list.delete.confirm'.tr()),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      if (!mounted) return;
      try {
        final notifier = ref.read(clothingItemsProvider.notifier);
        await notifier.deleteItem(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wardrobe.list.delete.success'.tr())),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wardrobe.list.delete.error'.tr(args: [e.toString()]))),
        );
      }
    }
  }
  
  Future<void> _showFilterDialog(BuildContext context) async {
    // Filtreleme ekranını göster
    // TODO: Gelişmiş filtreleme ekranı ekle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('wardrobe.list.filter.comingSoon'.tr())),
    );
  }
  
  String _getClothingTypeName(ClothingType type) {
    switch (type) {
      case ClothingType.tShirt:
        return 'clothing.tShirt'.tr();
      case ClothingType.shirt:
        return 'clothing.shirt'.tr();
      case ClothingType.blouse:
        return 'clothing.blouse'.tr();
      case ClothingType.sweater:
        return 'clothing.sweater'.tr();
      case ClothingType.jacket:
        return 'clothing.jacket'.tr();
      case ClothingType.coat:
        return 'clothing.coat'.tr();
      case ClothingType.jeans:
        return 'clothing.jeans'.tr();
      case ClothingType.pants:
        return 'clothing.pants'.tr();
      case ClothingType.shorts:
        return 'clothing.shorts'.tr();
      case ClothingType.skirt:
        return 'clothing.skirt'.tr();
      case ClothingType.dress:
        return 'clothing.dress'.tr();
      case ClothingType.shoes:
        return 'clothing.shoes'.tr();
      case ClothingType.boots:
        return 'clothing.boots'.tr();
      case ClothingType.accessory:
        return 'clothing.accessory'.tr();
      case ClothingType.hat:
        return 'clothing.hat'.tr();
      case ClothingType.scarf:
        return 'clothing.scarf'.tr();
      case ClothingType.other:
        return 'clothing.other'.tr();
    }
  }
  
  String _getSeasonName(Season season) {
    switch (season) {
      case Season.spring:
        return 'seasons.spring'.tr();
      case Season.summer:
        return 'seasons.summer'.tr();
      case Season.fall:
        return 'seasons.fall'.tr();
      case Season.winter:
        return 'seasons.winter'.tr();
      case Season.all:
        return 'seasons.allSeasons'.tr();
    }
  }
} 