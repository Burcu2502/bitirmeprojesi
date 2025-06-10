import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('helpAndSupport.faq'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'helpAndSupport.faq'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q1'.tr(),
            answer: 'helpAndSupport.faqContent.a1'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q2'.tr(),
            answer: 'helpAndSupport.faqContent.a2'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q3'.tr(),
            answer: 'helpAndSupport.faqContent.a3'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q4'.tr(),
            answer: 'helpAndSupport.faqContent.a4'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q5'.tr(),
            answer: 'helpAndSupport.faqContent.a5'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q6'.tr(),
            answer: 'helpAndSupport.faqContent.a6'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q7'.tr(),
            answer: 'helpAndSupport.faqContent.a7'.tr(),
          ),
          
          _buildFAQItem(
            context,
            question: 'helpAndSupport.faqContent.q8'.tr(),
            answer: 'helpAndSupport.faqContent.a8'.tr(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQItem(BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 