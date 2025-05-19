import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Dolaplarım'),
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
            return const Center(
              child: Text('Dolaplarınızda herhangi bir kıyafet bulunamadı. Eklemek için "+" butonuna tıklayın.'),
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
          child: Text('Kıyafetler yüklenirken bir hata oluştu: $error'),
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
        const SnackBar(content: Text('Kıyafet başarıyla eklendi')),
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
            Text('Tür: ${_getClothingTypeName(item.type)}'),
            const SizedBox(height: 8),
            Text('Mevsimler: ${item.seasons.map((s) => _getSeasonName(s)).join(', ')}'),
            if (item.brand != null) ...[
              const SizedBox(height: 8),
              Text('Marka: ${item.brand}'),
            ],
            if (item.material != null) ...[
              const SizedBox(height: 8),
              Text('Materyal: ${item.material}'),
            ],
            const SizedBox(height: 8),
            const Text('Renkler:'),
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
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editClothingItem(context, item);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }
  
  void _editClothingItem(BuildContext context, ClothingItemModel item) {
    // TODO: Düzenleme ekranına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Düzenleme özelliği yakında eklenecek')),
    );
  }
  
  Future<void> _deleteClothingItem(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kıyafeti Sil'),
        content: const Text('Bu kıyafeti silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
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
          const SnackBar(content: Text('Kıyafet başarıyla silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kıyafet silinirken hata oluştu: $e')),
        );
      }
    }
  }
  
  Future<void> _showFilterDialog(BuildContext context) async {
    // Filtreleme ekranını göster
    // TODO: Gelişmiş filtreleme ekranı ekle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtreleme özelliği yakında eklenecek')),
    );
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
        return 'Tüm Sezonlar';
    }
  }
} 