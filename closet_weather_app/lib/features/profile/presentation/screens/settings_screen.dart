import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/theme_provider.dart' as app_theme;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(app_theme.themeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.settings'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Görünüm Ayarları
          _buildSectionHeader(context, 'settings.appearance'),
          
          _buildThemeOption(context, ref, currentTheme),
          
          const SizedBox(height: 24),
          
          // Dil Ayarları
          _buildSectionHeader(context, 'settings.language'),
          
          _buildLanguageOption(context),
          
          const SizedBox(height: 24),
          
          // Bildirim Ayarları
          _buildSectionHeader(context, 'settings.notifications'),
          
          _buildNotificationOption(context),
          
          const SizedBox(height: 24),
          
          // Uygulama Hakkında
          _buildSectionHeader(context, 'settings.about'),
          
          _buildAboutOption(context),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(BuildContext context, WidgetRef ref, app_theme.ThemeMode currentTheme) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Karanlık Mod
            SwitchListTile(
              title: Text('settings.darkMode'.tr()),
              subtitle: Text('settings.darkModeDesc'.tr()),
              value: currentTheme == app_theme.ThemeMode.dark,
              secondary: Icon(
                currentTheme == app_theme.ThemeMode.dark 
                    ? Icons.dark_mode 
                    : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              onChanged: (value) {
                ref.read(app_theme.themeProvider.notifier).setThemeMode(
                  value ? app_theme.ThemeMode.dark : app_theme.ThemeMode.light
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption(BuildContext context) {
    // Mevcut dili al
    final currentLocale = context.locale;
    final languageCode = currentLocale.languageCode;
    final countryCode = currentLocale.countryCode;
    
    String currentLanguage = 'Türkçe';
    if (languageCode == 'en') {
      currentLanguage = 'English';
    }
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('settings.appLanguage'.tr()),
              subtitle: Text('${tr('settings.currentLang')} $currentLanguage'),
              trailing: const Icon(Icons.language),
              onTap: () {
                _showLanguageSelectDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationOption(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bildirimler
            SwitchListTile(
              title: Text('settings.enableNotifs'.tr()),
              subtitle: Text('settings.notifsDesc'.tr()),
              value: false, // Şimdilik kapalı
              secondary: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              onChanged: (value) {
                // Bildirim izinlerini yönet - şimdilik dummy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('general.featureNotAvailable'.tr()),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAboutOption(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('settings.version'.tr()),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.info_outline),
            ),
            const Divider(),
            ListTile(
              title: Text('settings.privacy'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('settings.privacyNotReady'.tr()),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text('settings.terms'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('settings.termsNotReady'.tr()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLanguageSelectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('settings.appLanguage'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Türkçe'),
                leading: Radio<String>(
                  value: 'tr',
                  groupValue: context.locale.languageCode,
                  onChanged: (value) {
                    context.setLocale(const Locale('tr', 'TR'));
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: context.locale.languageCode,
                  onChanged: (value) {
                    context.setLocale(const Locale('en', 'US'));
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('general.cancel'.tr()),
            ),
          ],
        );
      },
    );
  }
} 