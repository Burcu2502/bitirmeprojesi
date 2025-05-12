import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/outfit_recommendation_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OutfitSuggestionView extends ConsumerStatefulWidget {
  const OutfitSuggestionView({Key? key}) : super(key: key);

  @override
  ConsumerState<OutfitSuggestionView> createState() => _OutfitSuggestionViewState();
}

class _OutfitSuggestionViewState extends ConsumerState<OutfitSuggestionView> {
  final OutfitRecommendationService _recommendationService = OutfitRecommendationService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return const Center(
        child: Text('Kombin önerileri almak için giriş yapmalısınız.'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugün Ne Giysem?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Hava durumuna göre kombin önerisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Bugünün Hava Durumu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('22°C, Parçalı Bulutlu'),
                const Text('Bugün hafif serin, hafif yağmur ihtimali var.'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Önerilen Kombin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSuggestedOutfit(context),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // Simüle edilen bir gecikme
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    },
                    child: const Text('Yeni Kombin Oluştur'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Kişiselleştirilmiş Öneriler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: _buildPersonalizedSuggestions(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestedOutfit(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildClothingItem(
          context,
          icon: Icons.checkroom_outlined,
          label: 'Gömlek',
          description: 'Mavi Kot',
        ),
        _buildClothingItem(
          context,
          icon: Icons.roller_skating_outlined,
          label: 'Pantolon',
          description: 'Siyah Kot',
        ),
        _buildClothingItem(
          context,
          icon: Icons.umbrella_outlined,
          label: 'Dış Giyim',
          description: 'Hafif Hırka',
        ),
      ],
    );
  }
  
  Widget _buildClothingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonalizedSuggestions(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.checkroom,
                    size: 48,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kombin ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hafif serin günler için',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 