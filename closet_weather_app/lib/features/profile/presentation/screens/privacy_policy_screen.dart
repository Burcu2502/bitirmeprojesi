import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.privacyPolicy.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.privacyPolicy.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'settings.privacyPolicy.lastUpdated'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'settings.privacyPolicy.dataProtection'.tr(),
              'settings.privacyPolicy.dataProtectionDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.collectedData'.tr(),
              'settings.privacyPolicy.collectedDataList'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.dataUsage'.tr(),
              'settings.privacyPolicy.dataUsageList'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.dataSecurity'.tr(),
              'settings.privacyPolicy.dataSecurityDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.userRights'.tr(),
              'settings.privacyPolicy.userRightsDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.dataRetention'.tr(),
              'settings.privacyPolicy.dataRetentionDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.cookies'.tr(),
              'settings.privacyPolicy.cookiesDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.thirdParty'.tr(),
              'settings.privacyPolicy.thirdPartyDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.changes'.tr(),
              'settings.privacyPolicy.changesDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.privacyPolicy.contact'.tr(),
              'settings.privacyPolicy.contactDesc'.tr(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 