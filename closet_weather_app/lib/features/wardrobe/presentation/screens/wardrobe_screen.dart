import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
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
                decoration: InputDecoration(
                  hintText: 'general.search'.tr(),
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
            : Text('navigation.myClosets'.tr()),
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
                child: Text('wardrobe.errorLoadingItems'.tr() + ': $error'),
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
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.checkroom_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'wardrobe.emptyStateTitle'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'wardrobe.emptyStateDescription'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddClothingItemScreen()),
                );
                if (result == true) {
                  ref.invalidate(clothingItemsProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: Text('wardrobe.addFirstItem'.tr()),
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
                  Text(
                    'general.filter'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Kıyafet tipleri
                  Text(
                    'clothing.type'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(
                        label: 'clothing.tops'.tr(),
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
                        label: 'clothing.bottoms'.tr(),
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
                        label: 'clothing.outerwear'.tr(),
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
                  Text(
                    'seasons.title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(
                        label: 'seasons.spring'.tr(),
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
                        label: 'seasons.summer'.tr(),
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
                        label: 'seasons.fall'.tr(),
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
                        label: 'seasons.winter'.tr(),
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
                        child: Text('general.clearFilters'.tr()),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('general.apply'.tr()),
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