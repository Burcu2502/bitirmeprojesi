import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
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
        title: Text('weather.weather'.tr()),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('general.loading'.tr()),
          ],
        ),
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
              'weather.weatherUnavailable'.tr(),
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
              child: Text('weather.retry'.tr()),
            ),
          ],
        ),
      );
    }
    
    if (state.currentWeather == null) {
      return Center(
        child: Text('weather.weatherUnavailable'.tr()),
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
                    'weather.fiveDayForecast'.tr(),
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
                  'weather.suitableOutfits'.tr(),
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
        title: Text('weather.searchLocation'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'weather.enterCity'.tr(),
            prefixIcon: const Icon(Icons.location_city),
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
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(weatherStateProvider.notifier).updateLocation(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: Text('weather.search'.tr()),
          ),
        ],
      ),
    );
  }
} 