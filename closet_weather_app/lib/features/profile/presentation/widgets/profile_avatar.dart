import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../providers/profile_provider.dart';

class ProfileAvatar extends ConsumerWidget {
  final double size;
  final bool editable;

  const ProfileAvatar({
    super.key,
    this.size = 100,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final notifier = ref.read(profileProvider.notifier);

    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: profile?.photoURL != null 
              ? NetworkImage(profile!.photoURL!) 
              : null,
          child: profile?.photoURL == null
              ? Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade600)
              : null,
        ),
        if (editable)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickAndUploadImage(context, notifier),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, ProfileNotifier notifier) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Yükleme işlemi için bir SnackBar göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı yükleniyor...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Firebase Storage'a yükle
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask;
        final downloadURL = await snapshot.ref.getDownloadURL();
        
        // Provider ile profil fotoğrafını güncelle
        final success = await notifier.updateProfilePhoto(downloadURL);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Resim yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 