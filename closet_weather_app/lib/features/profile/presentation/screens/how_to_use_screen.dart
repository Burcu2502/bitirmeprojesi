import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('helpAndSupport.howToUse'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'helpAndSupport.howToUseContent.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step1'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step1Desc'.tr(),
              icon: Icons.person_add,
              color: Colors.blue,
            ),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step2'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step2Desc'.tr(),
              icon: Icons.style,
              color: Colors.purple,
            ),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step3'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step3Desc'.tr(),
              icon: Icons.add_a_photo,
              color: Colors.green,
            ),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step4'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step4Desc'.tr(),
              icon: Icons.location_on,
              color: Colors.orange,
            ),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step5'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step5Desc'.tr(),
              icon: Icons.recommend,
              color: Colors.teal,
            ),
            
            _buildStepCard(
              context,
              stepTitle: 'helpAndSupport.howToUseContent.step6'.tr(),
              stepDescription: 'helpAndSupport.howToUseContent.step6Desc'.tr(),
              icon: Icons.checkroom,
              color: Colors.indigo,
            ),
            
            const SizedBox(height: 24),
            
            // İpuçları Bölümü
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'helpAndSupport.howToUseContent.tips'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'helpAndSupport.howToUseContent.tip1'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'helpAndSupport.howToUseContent.tip2'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'helpAndSupport.howToUseContent.tip3'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'helpAndSupport.howToUseContent.tip4'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepCard(BuildContext context, {
    required String stepTitle,
    required String stepDescription,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 