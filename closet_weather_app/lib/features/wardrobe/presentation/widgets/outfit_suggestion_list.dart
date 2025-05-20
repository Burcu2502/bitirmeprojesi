import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/weather_model.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../weather/presentation/screens/outfit_recommendation_screen.dart';

class OutfitSuggestionList extends ConsumerWidget {
  const OutfitSuggestionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherStateProvider);
    
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.psychology),
              label: const Text('ML Kombin Önerilerini Göster'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: weatherState.currentWeather != null 
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OutfitRecommendationScreen(
                          weather: weatherState.currentWeather!,
                        ),
                      ),
                    );
                  }
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Yapay zeka destekli kıyafet önerileri için tıklayın',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 