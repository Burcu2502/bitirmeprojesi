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
      body: _buildBody(context, weatherState),
    );
  }
  
  Widget _buildBody(BuildContext context, WeatherState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(weatherStateProvider.notifier).refreshWeather(),
              child: Text('weather.retry'.tr()),
            ),
          ],
        ),
      );
    }
    
    if (state.currentWeather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('weather.weatherUnavailable'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(weatherStateProvider.notifier).getWeatherByCurrentLocation(),
              child: Text('weather.retry'.tr()),
            ),
          ],
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
  
  Future<void> _showSearchLocationDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('weather.searchLocation'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'weather.enterCity'.tr(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(weatherStateProvider.notifier).getWeatherByCity(value);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('weather.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(weatherStateProvider.notifier).getWeatherByCity(controller.text);
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