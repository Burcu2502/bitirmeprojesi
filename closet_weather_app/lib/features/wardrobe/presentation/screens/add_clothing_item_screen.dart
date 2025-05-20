import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/clothing_item_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/color_analysis_service.dart';

class AddClothingItemScreen extends ConsumerStatefulWidget {
  const AddClothingItemScreen({Key? key}) : super(key: key);

  @override
  _AddClothingItemScreenState createState() => _AddClothingItemScreenState();
}

class _AddClothingItemScreenState extends ConsumerState<AddClothingItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _materialController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final List<Color> _detectedColors = [];
  
  ClothingType _selectedType = ClothingType.tShirt;
  final List<Season> _selectedSeasons = [];
  
  bool _isLoading = false;
  
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ColorAnalysisService _colorAnalysisService = ColorAnalysisService();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _detectedColors.clear();
    });
    
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      
      // Renk analizi yap
      await _analyzeImageColors();
    }
  }
  
  Future<void> _takePhoto() async {
    setState(() {
      _detectedColors.clear();
    });
    
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      
      // Renk analizi yap
      await _analyzeImageColors();
    }
  }
  
  Future<void> _analyzeImageColors() async {
    if (_imageFile == null) return;
    
    try {
      final imageBytes = await _imageFile!.readAsBytes();
      final colors = await _colorAnalysisService.extractDominantColors(imageBytes, maxColors: 3);
      
      setState(() {
        _detectedColors.clear();
        _detectedColors.addAll(colors);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renk analizi yapılamadı: $e')),
      );
    }
  }
  
  Future<void> _saveClothingItem() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('wardrobe.imageSection.pleaseSelectImage'.tr())),
      );
      return;
    }
    if (_selectedSeasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('wardrobe.clothingDetails.pleaseSelectSeason'.tr())),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('wardrobe.clothingDetails.userSessionNotFound'.tr());
      }
      
      // Debug log ekleyelim
      debugPrint("📸 Resim yükleme başlıyor...");
      
      // Resmi Firebase Storage'a yükle
      final imageUrl = await _storageService.uploadClothingImage(userId, _imageFile!);
      
      debugPrint("✅ Resim yüklendi: $imageUrl");
      
      // Renk kodlarını elde et
      final List<String> colorHexCodes = _detectedColors.map((color) => 
        '#${color.value.toRadixString(16).substring(2, 8)}'
      ).toList();
      
      debugPrint("🎭 Kıyafet nesnesi oluşturuluyor...");
      
      // Kıyafet nesnesini oluştur - UUID burada üretmek yerine Firestore'un döndürdüğü ID'yi kullanacağız
      final clothingItem = ClothingItemModel(
        id: const Uuid().v4(), // Bu ID Firestore tarafından değiştirilecek
        userId: userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        colors: colorHexCodes,
        seasons: _selectedSeasons,
        material: _materialController.text.isEmpty ? null : _materialController.text.trim(),
        brand: _brandController.text.isEmpty ? null : _brandController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      debugPrint("💾 Firestore'a kayıt yapılıyor...");
      
      // Firestore'a kaydet
      final itemId = await _firestoreService.addClothingItem(clothingItem);
      
      debugPrint("✅ Kıyafet kaydedildi: $itemId");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wardrobe.clothingDetails.clothingSaved'.tr())),
        );
        Navigator.pop(context, true); // Başarılı olduğunda true döndür
      }
    } catch (e) {
      debugPrint("❌ Kıyafet kaydedilemedi: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('wardrobe.clothingDetails.errorSavingClothing')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('wardrobe.addClothingItem'.tr()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resim seçme alanı
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resim seçme butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text('wardrobe.imageSection.selectFromGallery'.tr()),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text('wardrobe.imageSection.takePhoto'.tr()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Algılanan renkler
                    if (_detectedColors.isNotEmpty) ...[
                      Text(
                        'wardrobe.clothingDetails.detectedColors'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _detectedColors.map((color) {
                          return Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Kıyafet bilgileri
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'wardrobe.clothingDetails.clothingName'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'wardrobe.clothingDetails.pleaseEnterName'.tr();
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Kıyafet tipi seçimi
                    DropdownButtonFormField<ClothingType>(
                      decoration: InputDecoration(
                        labelText: 'wardrobe.clothingDetails.clothingType'.tr(),
                        border: const OutlineInputBorder(),
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
                    Text(
                      'wardrobe.clothingDetails.seasons'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: Season.values.map((season) {
                        final isSelected = _selectedSeasons.contains(season);
                        return FilterChip(
                          label: Text(_getSeasonName(season)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSeasons.add(season);
                              } else {
                                _selectedSeasons.remove(season);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Marka (opsiyonel)
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'wardrobe.clothingDetails.brand'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Materyal (opsiyonel)
                    TextFormField(
                      controller: _materialController,
                      decoration: InputDecoration(
                        labelText: 'wardrobe.clothingDetails.material'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveClothingItem,
                        child: Text(
                          'wardrobe.clothingDetails.saveClothing'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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