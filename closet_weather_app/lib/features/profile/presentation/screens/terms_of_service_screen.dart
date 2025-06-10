import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.termsOfService.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.termsOfService.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'settings.termsOfService.lastUpdated'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'settings.termsOfService.acceptance'.tr(),
              'settings.termsOfService.acceptanceDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.serviceDescription'.tr(),
              'settings.termsOfService.serviceDescriptionDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.userResponsibilities'.tr(),
              'settings.termsOfService.userResponsibilitiesDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.prohibitedUses'.tr(),
              'settings.termsOfService.prohibitedUsesDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.intellectualProperty'.tr(),
              'settings.termsOfService.intellectualPropertyDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.disclaimer'.tr(),
              'settings.termsOfService.disclaimerDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.limitations'.tr(),
              'settings.termsOfService.limitationsDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.termination'.tr(),
              'settings.termsOfService.terminationDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.changes'.tr(),
              'settings.termsOfService.changesDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.governingLaw'.tr(),
              'settings.termsOfService.governingLawDesc'.tr(),
            ),
            
            _buildSection(
              context,
              'settings.termsOfService.contact'.tr(),
              'settings.termsOfService.contactDesc'.tr(),
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