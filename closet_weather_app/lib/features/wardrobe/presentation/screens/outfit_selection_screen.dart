import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/models/outfit_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../providers/wardrobe_provider.dart';

class OutfitSelectionScreen extends ConsumerStatefulWidget {
  final ClothingItemModel clothingItem;
  
  const OutfitSelectionScreen({
    Key? key,
    required this.clothingItem,
  }) : super(key: key);

  @override
  ConsumerState<OutfitSelectionScreen> createState() => _OutfitSelectionScreenState();
}

class _OutfitSelectionScreenState extends ConsumerState<OutfitSelectionScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _newOutfitNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newOutfitNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outfits = ref.watch(outfitsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kombine Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seçilen kıyafet bilgisi
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: widget.clothingItem.imageUrl != null &&
                                    widget.clothingItem.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.clothingItem.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.checkroom,
                                          color: Colors.grey[600],
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.checkroom,
                                    color: Colors.grey[600],
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.clothingItem.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getClothingTypeName(widget.clothingItem.type),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Yeni kombin oluşturma seçeneği
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Yeni Kombin Oluştur'),
                      subtitle: const Text('Bu kıyafetle yeni bir kombin başlat'),
                      onTap: _showNewOutfitDialog,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mevcut kombinler
                  Text(
                    'Mevcut Kombinlere Ekle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: outfits.isEmpty
                        ? const Center(
                            child: Text('Henüz kombin oluşturmadınız'),
                          )
                        : ListView.builder(
                            itemCount: outfits.length,
                            itemBuilder: (context, index) {
                              final outfit = outfits[index];
                              final isAlreadyInOutfit = outfit.clothingItemIds.contains(widget.clothingItem.id);
                              
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    isAlreadyInOutfit ? Icons.check_circle : Icons.style,
                                    color: isAlreadyInOutfit 
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  title: Text(outfit.name),
                                  subtitle: Text(
                                    '${outfit.clothingItemIds.length} parça • ${_getOccasionName(outfit.occasion)}',
                                  ),
                                  trailing: isAlreadyInOutfit
                                      ? Icon(
                                          Icons.check,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                  onTap: isAlreadyInOutfit
                                      ? null
                                      : () => _addToExistingOutfit(outfit),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showNewOutfitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kombin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newOutfitNameController,
              decoration: const InputDecoration(
                labelText: 'Kombin Adı',
                hintText: 'Örn: Günlük Kombin',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu kıyafetle yeni bir kombin oluşturulacak. Daha sonra başka kıyafetler de ekleyebilirsiniz.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _createNewOutfit,
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewOutfit() async {
    final name = _newOutfitNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kombin adı boş olamaz')),
      );
      return;
    }

    Navigator.of(context).pop(); // Dialog'u kapat
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final outfit = OutfitModel(
        id: const Uuid().v4(),
        userId: user.uid,
        name: name,
        description: 'Yeni oluşturulan kombin',
        clothingItemIds: [widget.clothingItem.id],
        seasons: widget.clothingItem.seasons,
        weatherConditions: [WeatherCondition.any],
        occasion: Occasion.casual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.addOutfit(outfit);
      
      // Provider'ı güncelle
      ref.invalidate(outfitsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name kombini oluşturuldu')),
        );
        Navigator.of(context).pop(true); // Ana ekrana dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kombin oluşturulamadı: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToExistingOutfit(OutfitModel outfit) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOutfit = outfit.copyWith(
        clothingItemIds: [...outfit.clothingItemIds, widget.clothingItem.id],
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateOutfit(updatedOutfit);
      
      // Provider'ı güncelle
      ref.invalidate(outfitsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${outfit.name} kombinine eklendi')),
        );
        Navigator.of(context).pop(true); // Ana ekrana dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kombine eklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getClothingTypeName(ClothingType type) {
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

  String _getOccasionName(Occasion occasion) {
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
} 