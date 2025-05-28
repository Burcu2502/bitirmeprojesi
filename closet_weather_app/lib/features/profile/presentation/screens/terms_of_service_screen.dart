import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.terms.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.terms.title',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.serviceTerms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.serviceTermsDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.usageRights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.usageRightsList',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.restrictions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.restrictionsList',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.disclaimer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.disclaimerDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.changes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.changesDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
            const SizedBox(height: 16),
            Text(
              'settings.terms.contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).tr(),
            const SizedBox(height: 8),
            Text(
              'settings.terms.contactDesc',
              style: Theme.of(context).textTheme.bodyLarge,
            ).tr(),
          ],
        ),
      ),
    );
  }
} 