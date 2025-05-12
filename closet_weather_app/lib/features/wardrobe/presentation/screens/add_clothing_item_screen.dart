import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
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
        const SnackBar(content: Text('Lütfen bir resim seçin')),
      );
      return;
    }
    if (_selectedSeasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir mevsim seçin')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Resmi Firebase Storage'a yükle
      final imageUrl = await _storageService.uploadClothingImage(userId, _imageFile!);
      
      // Renk kodlarını elde et
      final List<String> colorHexCodes = _detectedColors.map((color) => 
        '#${color.value.toRadixString(16).substring(2, 8)}'
      ).toList();
      
      // Kıyafet nesnesini oluştur
      final clothingItem = ClothingItemModel(
        id: const Uuid().v4(),
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
      
      // Firestore'a kaydet
      await _firestoreService.addClothingItem(clothingItem);
      
      if (mounted) {
        Navigator.pop(context, true); // Başarılı olduğunda true döndür
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kıyafet kaydedilemedi: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıyafet Ekle'),
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
                          label: const Text('Galeriden Seç'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Fotoğraf Çek'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Algılanan renkler
                    if (_detectedColors.isNotEmpty) ...[
                      const Text(
                        'Algılanan Renkler:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      decoration: const InputDecoration(
                        labelText: 'Kıyafet Adı',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen bir isim girin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Kıyafet tipi seçimi
                    DropdownButtonFormField<ClothingType>(
                      decoration: const InputDecoration(
                        labelText: 'Kıyafet Tipi',
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
                      'Mevsimler:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      decoration: const InputDecoration(
                        labelText: 'Marka (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Materyal (opsiyonel)
                    TextFormField(
                      controller: _materialController,
                      decoration: const InputDecoration(
                        labelText: 'Materyal (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveClothingItem,
                        child: const Text(
                          'Kıyafeti Kaydet',
                          style: TextStyle(fontSize: 16),
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