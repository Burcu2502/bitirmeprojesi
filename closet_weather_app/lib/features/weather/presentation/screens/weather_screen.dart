import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/weather_provider.dart';
import '../widgets/weather_display.dart';
import '../widgets/weather_forecast_list.dart';
import '../../../wardrobe/presentation/widgets/outfit_suggestion_list.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});
  
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hava Durumu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchLocationDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: weatherState.isLoading
                ? null
                : () => ref.read(weatherStateProvider.notifier).fetchWeatherData(),
          ),
        ],
      ),
      body: _buildBody(context, weatherState),
    );
  }
  
  Widget _buildBody(BuildContext context, WeatherState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Hava durumu alınamadı',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(weatherStateProvider.notifier).fetchWeatherData(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    if (state.currentWeather == null) {
      return const Center(
        child: Text('Hava durumu bilgisi bulunamadı.'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(weatherStateProvider.notifier).fetchWeatherData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mevcut hava durumu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: WeatherDisplay(weather: state.currentWeather!),
              ),
              
              const Divider(height: 32),
              
              // Hava tahmini
              if (state.forecast != null && state.forecast!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '5 Günlük Tahmin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                WeatherForecastList(forecast: state.forecast!),
                
                const Divider(height: 32),
              ],
              
              // Kıyafet önerileri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Bu Havaya Uygun Kombinler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const OutfitSuggestionList(), // TODO: Implement this widget
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSearchLocationDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Ara'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Şehir adı girin',
            prefixIcon: Icon(Icons.location_city),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(weatherStateProvider.notifier).updateLocation(value);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(weatherStateProvider.notifier).updateLocation(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }
} 