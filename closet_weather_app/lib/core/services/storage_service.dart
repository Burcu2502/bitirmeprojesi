import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String clothingImagesPath = 'clothing_images';
  static const String outfitImagesPath = 'outfit_images';
  
  // Kıyafet resmini Firebase Storage'a yükler
  Future<String> uploadClothingImage(String userId, File imageFile) async {
    final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
    final Reference ref = _storage.ref().child('$clothingImagesPath/$userId/$fileName');
    
    try {
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Byte array'i kullanarak resim yükleme (web için)
  Future<String> uploadClothingImageFromBytes(String userId, Uint8List imageBytes) async {
    final String fileName = '${const Uuid().v4()}.jpg';
    final Reference ref = _storage.ref().child('$clothingImagesPath/$userId/$fileName');
    
    try {
      final UploadTask uploadTask = ref.putData(
        imageBytes, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Kombin resmini Firebase Storage'a yükler
  Future<String> uploadOutfitImage(String userId, File imageFile) async {
    final String fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
    final Reference ref = _storage.ref().child('$outfitImagesPath/$userId/$fileName');
    
    try {
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Firebase Storage'dan resim sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
} 