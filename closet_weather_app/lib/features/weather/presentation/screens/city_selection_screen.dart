import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/weather_provider.dart';
import '../widgets/city_selection_widget.dart';

class CitySelectionScreen extends ConsumerStatefulWidget {
  const CitySelectionScreen({super.key});
  
  @override
  ConsumerState<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends ConsumerState<CitySelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('weather.selectCity'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Mevcut konumu kullan butonu
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'weather.citySelection.useCurrentLocation'.tr(),
            onPressed: weatherState.isLoading 
                ? null 
                : () async {
                    await ref.read(weatherStateProvider.notifier).getWeatherByCurrentLocation();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bilgilendirme kartı
              if (weatherState.locationFailed)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'weather.citySelection.locationFailedMessage'.tr(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Ana şehir seçim widget'ı
              Expanded(
                child: CitySelectionWidget(
                  onCitySelected: () {
                    // Şehir seçildikten sonra bir süre bekleyip geri dön
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  },
                ),
              ),
              
              // Alt bilgi
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'weather.citySelection.tip'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 