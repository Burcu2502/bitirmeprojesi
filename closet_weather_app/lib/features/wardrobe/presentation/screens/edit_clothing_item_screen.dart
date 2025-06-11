import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/color_analysis_service.dart';
import '../providers/wardrobe_provider.dart';

class EditClothingItemScreen extends ConsumerStatefulWidget {
  final ClothingItemModel item;
  
  const EditClothingItemScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  _EditClothingItemScreenState createState() => _EditClothingItemScreenState();
}

class _EditClothingItemScreenState extends ConsumerState<EditClothingItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _materialController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Color> _detectedColors = [];
  
  late ClothingType _selectedType;
  late List<Season> _selectedSeasons;
  
  bool _isLoading = false;
  bool _isAnalyzingColors = false;
  bool _imageChanged = false;
  
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ColorAnalysisService _colorAnalysisService = ColorAnalysisService();

  @override
  void initState() {
    super.initState();
    // Mevcut kıyafet bilgilerini form alanlarına doldur
    _nameController = TextEditingController(text: widget.item.name);
    _brandController = TextEditingController(text: widget.item.brand ?? '');
    _materialController = TextEditingController(text: widget.item.material ?? '');
    _selectedType = widget.item.type;
    _selectedSeasons = List.from(widget.item.seasons);
    
    // Mevcut renkleri Color objesine çevir
    _detectedColors = widget.item.colors.map((colorHex) {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _materialController.dispose();
    _imageFile?.delete().catchError((e) => debugPrint('Dosya silinirken hata: $e'));
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.status;
        if (status.isDenied) {
          final result = await Permission.camera.request();
          if (result.isDenied) {
            _showPermissionDialog('Kamera');
            return;
          }
        }
      } else {
        final status = await Permission.photos.status;
        if (status.isDenied) {
          final result = await Permission.photos.request();
          if (result.isDenied) {
            _showPermissionDialog('Galeri');
            return;
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageChanged = true;
        });
        
        // Renk analizi yap
        await _analyzeColors();
      }
    } catch (e) {
      debugPrint('Resim seçilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType İzni Gerekli'),
        content: Text('$permissionType kullanmak için izin vermeniz gerekiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeColors() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isAnalyzingColors = true;
    });

    try {
      final imageBytes = await _imageFile!.readAsBytes();
      final colors = await _colorAnalysisService.extractDominantColors(imageBytes, maxColors: 5);
      setState(() {
        _detectedColors = colors;
        _isAnalyzingColors = false;
      });
    } catch (e) {
      debugPrint('Renk analizi hatası: $e');
      setState(() {
        _isAnalyzingColors = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeColor(int index) {
    setState(() {
      _detectedColors.removeAt(index);
    });
  }

  void _toggleSeason(Season season) {
    setState(() {
      if (_selectedSeasons.contains(season)) {
        _selectedSeasons.remove(season);
      } else {
        _selectedSeasons.add(season);
      }
    });
  }

  Future<void> _updateClothingItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSeasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir mevsim seçmelisiniz')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = widget.item.imageUrl;
      
      // Eğer resim değiştiyse yeni resmi yükle
      if (_imageChanged && _imageFile != null) {
        final user = _authService.currentUser;
        if (user != null) {
          // Eski resmi sil (eğer varsa)
          if (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty) {
            try {
              await _storageService.deleteImage(widget.item.imageUrl!);
            } catch (e) {
              debugPrint('Eski resim silinirken hata: $e');
            }
          }
          
          // Yeni resmi yükle
          imageUrl = await _storageService.uploadClothingImage(user.uid, _imageFile!);
        }
      }

      // Güncellenmiş kıyafet objesi oluştur
      final updatedItem = widget.item.copyWith(
        name: _nameController.text,
        type: _selectedType,
        colors: _detectedColors.map((color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}').toList(),
        seasons: _selectedSeasons,
        material: _materialController.text.isEmpty ? null : _materialController.text,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      // Firestore'da güncelle
      await _firestoreService.updateClothingItem(updatedItem);
      
      debugPrint("✅ Kıyafet güncellendi: ${updatedItem.id}");
      
      // Provider cache'ini invalidate et
      ref.invalidate(clothingItemsProvider);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kıyafet başarıyla güncellendi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("❌ Kıyafet güncellenemedi: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kıyafet güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıyafeti Düzenle'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TextButton(
              onPressed: _updateClothingItem,
              child: const Text('Güncelle'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resim seçimi
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.grey[700],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey[700],
                              ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Kıyafet adı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kıyafet Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kıyafet adı boş olamaz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Marka
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marka (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Materyal
              TextFormField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Materyal (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Kıyafet türü
              DropdownButtonFormField<ClothingType>(
                decoration: const InputDecoration(
                  labelText: 'Kıyafet Türü',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: ClothingType.values.map((type) {
                  return DropdownMenuItem<ClothingType>(
                    value: type,
                    child: Text(_getClothingTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Mevsim seçimi
              const Text(
                'Uygun Mevsimler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Season.values.map((season) {
                  final isSelected = _selectedSeasons.contains(season);
                  return FilterChip(
                    label: Text(_getSeasonName(season)),
                    selected: isSelected,
                    onSelected: (selected) => _toggleSeason(season),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Renkler
              const Text(
                'Renkler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isAnalyzingColors)
                const Center(child: CircularProgressIndicator())
              else if (_detectedColors.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detectedColors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final color = entry.value;
                    return Chip(
                      backgroundColor: color,
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeColor(index),
                      label: Text(
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                        style: TextStyle(
                          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                const Text('Renk analizi için resim seçin'),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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
    }
  }
} 