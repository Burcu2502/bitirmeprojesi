import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';

class CitySelectionWidget extends ConsumerStatefulWidget {
  final VoidCallback? onCitySelected;
  
  const CitySelectionWidget({
    super.key,
    this.onCitySelected,
  });
  
  @override
  ConsumerState<CitySelectionWidget> createState() => _CitySelectionWidgetState();
}

class _CitySelectionWidgetState extends ConsumerState<CitySelectionWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final suggestions = ref.read(weatherStateProvider.notifier).getCitySuggestions(query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectCity(String city) {
    ref.read(weatherStateProvider.notifier).getWeatherByCity(city);
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onCitySelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteCities = ref.watch(favoriteCitiesProvider);
    final weatherState = ref.watch(weatherStateProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama alanı
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Şehir ara veya seç...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _updateSuggestions('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: _updateSuggestions,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _selectCity(value.trim());
            }
          },
        ),
        
        const SizedBox(height: 8),
        
        // Mevcut şehir bilgisi
        if (weatherState.currentWeather != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  weatherState.locationFailed ? Icons.location_off : Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'Şu an: ${weatherState.currentCity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Öneriler veya favori şehirler
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          Text(
            'Öneriler:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_suggestions.length, (index) {
            final city = _suggestions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: const Icon(Icons.location_city, size: 20),
                title: Text(city),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _selectCity(city),
              ),
            );
          }),
        ] else if (!_showSuggestions) ...[
          Row(
            children: [
              Text(
                'Popüler Şehirler:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (weatherState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Favori şehirler grid'i
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3,
            ),
            itemCount: favoriteCities.length,
            itemBuilder: (context, index) {
              final city = favoriteCities[index];
              final isSelected = weatherState.currentCity == city;
              
              return InkWell(
                onTap: weatherState.isLoading ? null : () => _selectCity(city),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            city,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
} 