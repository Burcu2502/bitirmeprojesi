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
  // Stillerin çevirileri için anahtar listesi
  final List<String> availableStyleKeys = [
    'casual',
    'formal',
    'sporty',
    'minimalist',
    'romantic',
    'vintage',
    'bohemian',
    'classic',
    'streetwear',
    'elegant',
    'retro',
    'businessCasual',
    'smart',
    'preppy',
    'grunge',
    'gothic',
    'rock',
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
                // Başlık ve Açıklama
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'stylePreferences.myStylePreferences'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'stylePreferences.selectStyles'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Seçim bilgisi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'stylePreferences.selectedCount'.tr() + ' ${selectedStyles.length}/${availableStyleKeys.length}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stil listesi
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: availableStyleKeys.length,
                      itemBuilder: (context, index) {
                        final styleKey = availableStyleKeys[index];
                        final isSelected = selectedStyles.contains(styleKey);
                        
                        return _buildStyleTile(styleKey, isSelected);
                      },
                    ),
                  ),
                ),
                
                // Kaydet butonu
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      child: _isSaving
                          ? SizedBox(
                              width: 24, 
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
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
  
  // Stil anahtarından görünen metin oluştur
  String _getTranslatedStyleName(String styleKey) {
    // Çeviri anahtarını oluştur
    final translationKey = 'styles.$styleKey';
    
    // Çeviriyi kontrol et
    if (translationKey.tr() != translationKey) {
      // Çeviri varsa kullan
      return translationKey.tr();
    } else {
      // Çeviri yoksa, anahtarı büyük harfle başlat
      return styleKey.substring(0, 1).toUpperCase() + styleKey.substring(1);
    }
  }
  
  Widget _buildStyleTile(String styleKey, bool isSelected) {
    final styleName = _getTranslatedStyleName(styleKey);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 0,
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            styleName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
              : Icon(Icons.circle_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedStyles.remove(styleKey);
              } else {
                selectedStyles.add(styleKey);
              }
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
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
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('general.error'.tr()),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('general.error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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