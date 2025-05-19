import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/clothing_grid_item.dart';
import '../widgets/filter_chip_list.dart';
import 'add_clothing_item_screen.dart';
import 'clothing_item_detail_screen.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  
  var _filter = ClothingFilter();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kıyafetleri filtrele
    final filteredItems = ref.watch(filteredClothingItemsProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Kıyafet ara...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _filter = ClothingFilter(
                      types: _filter.types,
                      seasons: _filter.seasons,
                      colors: _filter.colors,
                      searchQuery: value,
                    );
                  });
                },
                autofocus: true,
              )
            : const Text('Dolaplarım'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filter = ClothingFilter(
                    types: _filter.types,
                    seasons: _filter.seasons,
                    colors: _filter.colors,
                  );
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Aktif filtreler
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilterChipList(
                filter: _filter,
                onFilterChanged: (newFilter) {
                  setState(() {
                    _filter = newFilter;
                  });
                },
              ),
            ),
          
          // Kıyafet listesi
          Expanded(
            child: filteredItems.when(
              data: (items) => _buildClothingGrid(items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Kıyafetler yüklenirken hata: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClothingItemScreen()),
          );
          if (result == true) {
            // Kıyafet eklendiyse, listeyi yenile
            ref.invalidate(clothingItemsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Kıyafet ızgarası
  Widget _buildClothingGrid(List<ClothingItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood_bad,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz kıyafet eklenmemiş',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dolabınıza yeni kıyafetler eklemek için + butonuna tıklayın',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ClothingGridItem(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClothingItemDetailScreen(item: item),
              ),
            ).then((updated) {
              if (updated == true) {
                // Eğer kıyafet güncellenirse listeyi yenile
                ref.invalidate(clothingItemsProvider);
              }
            });
          },
        );
      },
    );
  }
  
  // Filtreleme alt menüsü
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  const Text(
                    'Filtreleme Seçenekleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Kıyafet tipleri
                  const Text(
                    'Kıyafet Tipi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(
                        label: 'Üst Giyim',
                        selected: _filter.types?.contains(ClothingType.tShirt) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _updateList<ClothingType>(
                                _filter.types,
                                ClothingType.tShirt,
                                selected,
                              ),
                              seasons: _filter.seasons,
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                      _filterChip(
                        label: 'Alt Giyim',
                        selected: _filter.types?.contains(ClothingType.pants) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _updateList<ClothingType>(
                                _filter.types,
                                ClothingType.pants,
                                selected,
                              ),
                              seasons: _filter.seasons,
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                      _filterChip(
                        label: 'Dış Giyim',
                        selected: _filter.types?.contains(ClothingType.jacket) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _updateList<ClothingType>(
                                _filter.types,
                                ClothingType.jacket,
                                selected,
                              ),
                              seasons: _filter.seasons,
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mevsimler
                  const Text(
                    'Mevsim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(
                        label: 'İlkbahar',
                        selected: _filter.seasons?.contains(Season.spring) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _filter.types,
                              seasons: _updateList<Season>(
                                _filter.seasons,
                                Season.spring,
                                selected,
                              ),
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                      _filterChip(
                        label: 'Yaz',
                        selected: _filter.seasons?.contains(Season.summer) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _filter.types,
                              seasons: _updateList<Season>(
                                _filter.seasons,
                                Season.summer,
                                selected,
                              ),
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                      _filterChip(
                        label: 'Sonbahar',
                        selected: _filter.seasons?.contains(Season.fall) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _filter.types,
                              seasons: _updateList<Season>(
                                _filter.seasons,
                                Season.fall,
                                selected,
                              ),
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                      _filterChip(
                        label: 'Kış',
                        selected: _filter.seasons?.contains(Season.winter) ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _filter = ClothingFilter(
                              types: _filter.types,
                              seasons: _updateList<Season>(
                                _filter.seasons,
                                Season.winter,
                                selected,
                              ),
                              colors: _filter.colors,
                              searchQuery: _filter.searchQuery,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            this.setState(() {
                              _filter = ClothingFilter();
                            });
                          });
                        },
                        child: const Text('Filtreleri Temizle'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Uygula'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _filterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    );
  }
  
  List<T>? _updateList<T>(List<T>? list, T item, bool add) {
    if (list == null) {
      return add ? [item] : null;
    }
    
    final newList = List<T>.from(list);
    if (add && !newList.contains(item)) {
      newList.add(item);
    } else if (!add && newList.contains(item)) {
      newList.remove(item);
    }
    
    return newList.isEmpty ? null : newList;
  }
  
  bool _hasActiveFilters() {
    return (_filter.types != null && _filter.types!.isNotEmpty) ||
           (_filter.seasons != null && _filter.seasons!.isNotEmpty) ||
           (_filter.colors != null && _filter.colors!.isNotEmpty) ||
           (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty);
  }
} 