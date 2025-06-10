import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'faq_screen.dart';
import 'how_to_use_screen.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('helpAndSupport.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'helpAndSupport.description'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // İletişim Seçenekleri
            Text(
              'helpAndSupport.contactUs'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Doğrudan İletişim Kartı
            Card(
              elevation: 2,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text('helpAndSupport.contactDirect'.tr()),
                subtitle: Text('helpAndSupport.supportEmail'.tr()),
                trailing: const Icon(Icons.copy, size: 16),
                onTap: () => _copyEmail(context),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Yardım Kategorileri
            Text(
              'helpAndSupport.commonIssues'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nasıl Kullanılır
            _buildCategoryCard(
              context,
              icon: Icons.help_outline,
              title: 'helpAndSupport.howToUse'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HowToUseScreen()),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // SSS
            _buildCategoryCard(
              context,
              icon: Icons.quiz_outlined,
              title: 'helpAndSupport.faq'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQScreen()),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Uygulama Bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'helpAndSupport.appVersion'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Platform: ${Platform.operatingSystem}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  
  void _copyEmail(BuildContext context) {
    final email = 'helpAndSupport.supportEmail'.tr();
    Clipboard.setData(ClipboardData(text: email));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('helpAndSupport.emailCopied'.tr()),
        backgroundColor: Colors.green,
      ),
    );
  }
} 