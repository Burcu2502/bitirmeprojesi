import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.privacy.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.privacy.title',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.privacy.dataProtection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.privacy.dataProtectionDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.privacy.collectedData',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.privacy.collectedDataList',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.privacy.dataUsage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.privacy.dataUsageList',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.privacy.dataSecurity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.privacy.dataSecurityDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.privacy.contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.privacy.contactDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
          ],
        ),
      ),
    );
  }
} 