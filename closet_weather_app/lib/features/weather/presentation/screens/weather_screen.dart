import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../presentation/providers/weather_provider.dart';
import '../widgets/weather_display.dart';
import '../widgets/weather_forecast_list.dart';
import '../../../wardrobe/presentation/widgets/outfit_suggestion_list.dart';
import 'city_selection_screen.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});
  
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherStateProvider);
    final favoriteCities = ref.watch(favoriteCitiesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('weather.weatherAndOutfit'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CitySelectionScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: weatherState.isLoading
                ? null
                : () => ref.read(weatherStateProvider.notifier).refreshWeather(),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: weatherState.isLoading
                ? null
                : () => ref.read(weatherStateProvider.notifier).getWeatherByCurrentLocation(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Konum durumu bilgilendirme banner'ı
          if (weatherState.locationFailed && weatherState.currentWeather != null)
            _buildLocationFallbackBanner(context, weatherState),
          
          // Ana içerik
          Expanded(
            child: _buildBody(context, weatherState),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationFallbackBanner(BuildContext context, WeatherState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'weather.citySelection.locationNotAvailable'.tr(namedArgs: {'city': state.currentCity}),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CitySelectionScreen(),
                ),
              );
            },
            child: Text(
              'weather.citySelection.change'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody(BuildContext context, WeatherState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ref.read(weatherStateProvider.notifier).refreshWeather(),
                    icon: const Icon(Icons.refresh),
                    label: Text('weather.retry'.tr()),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CitySelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: Text('weather.citySelection.selectCity'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    if (state.currentWeather == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'weather.weatherUnavailable'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ref.read(weatherStateProvider.notifier).getWeatherByCurrentLocation(),
                    icon: const Icon(Icons.my_location),
                    label: Text('weather.citySelection.useCurrentLocation'.tr()),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CitySelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: Text('weather.citySelection.selectCity'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(weatherStateProvider.notifier).refreshWeather(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WeatherDisplay(weather: state.currentWeather!),
          const SizedBox(height: 24),
          if (state.forecast != null && state.forecast!.isNotEmpty) ...[
            Text(
              'weather.forecast'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            WeatherForecastList(forecast: state.forecast!),
            const SizedBox(height: 24),
          ],
          Text(
            'wardrobe.suggestedOutfit'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          OutfitSuggestionList(weather: state.currentWeather!),
        ],
      ),
    );
  }
} 