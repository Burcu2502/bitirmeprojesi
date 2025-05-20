import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/profile_provider.dart';

class StylePreferencesScreen extends ConsumerStatefulWidget {
  const StylePreferencesScreen({super.key});

  @override
  ConsumerState<StylePreferencesScreen> createState() => _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends ConsumerState<StylePreferencesScreen> {
  final List<String> availableStyles = [
    'Casual',
    'Formal',
    'Sporty',
    'Minimalist',
    'Romantic',
    'Vintage',
    'Bohemian',
    'Classic',
    'Streetwear',
    'Elegant',
    'Retro',
    'Business Casual',
    'Smart',
    'Preppy',
    'Grunge',
    'Gothic',
    'Rock',
  ];
  
  Set<String> selectedStyles = {};
  bool _isSaving = false;
  
  @override
  Widget build(BuildContext context) {
    // Profile verisini izleyin
    final profileState = ref.watch(profileProvider);
    
    // Profil yüklendiğinde (ve yalnızca bir kez) seçili stilleri alın
    if (profileState.status == ProfileStatus.loaded && selectedStyles.isEmpty) {
      _loadSavedStyles(profileState);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('stylePreferences.myStylePreferences'.tr()),
        centerTitle: true,
      ),
      body: profileState.status == ProfileStatus.loading && selectedStyles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'stylePreferences.myStylePreferences'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'stylePreferences.selectStyles'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: availableStyles.length,
                    itemBuilder: (context, index) {
                      final style = availableStyles[index];
                      final isSelected = selectedStyles.contains(style);
                      
                      return _buildStyleTile(style, isSelected);
                    },
                  ),
                ),
                
                // Seçilen stil bilgisi
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'stylePreferences.selectedCount'.tr() + ' ${selectedStyles.length}/${availableStyles.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Alt kısımdaki kaydet butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePreferences,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'stylePreferences.save'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  // Kaydedilmiş stilleri yükle
  void _loadSavedStyles(ProfileState profileState) {
    debugPrint('🔄 Kaydedilmiş stiller yükleniyor...');
    try {
      if (profileState.profile?.preferences != null && 
          profileState.profile!.preferences!.containsKey('stylePreferences')) {
        
        final prefList = profileState.profile!.preferences!['stylePreferences'] as List;
        
        // String'e dönüştür
        final styles = prefList.map((item) => item.toString()).toSet();
        
        setState(() {
          selectedStyles = styles;
        });
        
        debugPrint('✅ ${styles.length} stil yüklendi: $styles');
      } else {
        debugPrint('ℹ️ Kaydedilmiş stil tercihi bulunamadı');
      }
    } catch (e) {
      debugPrint('❌ Stil tercihleri yüklenirken hata: $e');
    }
  }
  
  Widget _buildStyleTile(String style, bool isSelected) {
    return ListTile(
      title: Text(style),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedStyles.remove(style);
          } else {
            selectedStyles.add(style);
          }
        });
      },
    );
  }
  
  Future<void> _savePreferences() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    // Mevcut preferences'ı al
    final profileState = ref.read(profileProvider);
    Map<String, dynamic> preferences = 
        Map<String, dynamic>.from(profileState.profile?.preferences ?? {});
    
    // Stil tercihlerini güncelle
    preferences['stylePreferences'] = selectedStyles.toList();
    
    debugPrint('💾 Kaydedilen stiller: $selectedStyles');
    
    // Profili güncelle
    try {
      // Önce profil yeniden yükleyin (güncel verileri almak için)
      await ref.read(profileProvider.notifier).loadUserProfile();
      
      final success = await ref.read(profileProvider.notifier).updatePreferences(preferences);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('general.success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('general.error'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('general.error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
} 