import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/models/outfit_model.dart';

class WeatherDisplay extends StatelessWidget {
  final WeatherModel weather;
  
  const WeatherDisplay({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.location,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(weather.timestamp),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                _getWeatherIcon(weather.condition),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tr('weather.feelsLike')} ${weather.feelsLike.toStringAsFixed(1)}°C',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        weather.description.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getWeatherAdvice(weather),
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: _buildWeatherDetail(
                    context, 
                    Icons.water_drop_outlined, 
                    tr('weather.humidity'),
                    '${weather.humidity}%',
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: _buildWeatherDetail(
                    context, 
                    Icons.air, 
                    tr('weather.wind'),
                    '${weather.windSpeed} km/s',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return '${tr('weather.today')}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == today.add(const Duration(days: 1))) {
      return '${tr('weather.tomorrow')}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _getWeatherIcon(WeatherCondition condition) {
    IconData iconData;
    Color color;
    
    switch (condition) {
      case WeatherCondition.sunny:
        iconData = Icons.wb_sunny;
        color = Colors.amber;
        break;
      case WeatherCondition.partlyCloudy:
        iconData = Icons.wb_cloudy;
        color = Colors.amber;
        break;
      case WeatherCondition.cloudy:
        iconData = Icons.cloud;
        color = Colors.grey;
        break;
      case WeatherCondition.rainy:
        iconData = Icons.water_drop;
        color = Colors.blue;
        break;
      case WeatherCondition.stormy:
        iconData = Icons.flash_on;
        color = Colors.deepPurple;
        break;
      case WeatherCondition.snowy:
        iconData = Icons.ac_unit;
        color = Colors.lightBlue;
        break;
      case WeatherCondition.windy:
        iconData = Icons.air;
        color = Colors.blueGrey;
        break;
      case WeatherCondition.foggy:
        iconData = Icons.cloud;
        color = Colors.grey;
        break;
      case WeatherCondition.hot:
        iconData = Icons.whatshot;
        color = Colors.deepOrange;
        break;
      case WeatherCondition.cold:
        iconData = Icons.ac_unit;
        color = Colors.blue;
        break;
      case WeatherCondition.mild:
        iconData = Icons.wb_twilight;
        color = Colors.orange;
        break;
      case WeatherCondition.any:
      default:
        iconData = Icons.help_outline;
        color = Colors.grey;
        break;
    }
    
    return Icon(
      iconData,
      size: 50,
      color: color,
    );
  }

  String _getWeatherAdvice(WeatherModel weather) {
    if (weather.isHot) {
      return tr('weather.advice.veryHot');
    } else if (weather.isWarm) {
      return tr('weather.advice.hot');
    } else if (weather.isMild) {
      return tr('weather.advice.mild');
    } else if (weather.isCool) {
      return tr('weather.advice.cool');
    } else if (weather.isCold) {
      return tr('weather.advice.cold');
    }
    
    switch (weather.condition) {
      case WeatherCondition.rainy:
        return tr('weather.advice.rainy');
      case WeatherCondition.stormy:
        return tr('weather.advice.stormy');
      case WeatherCondition.snowy:
        return tr('weather.advice.snowy');
      case WeatherCondition.windy:
        return tr('weather.advice.windy');
      case WeatherCondition.foggy:
        return tr('weather.advice.foggy');
      case WeatherCondition.hot:
        return tr('weather.advice.drinkWater');
      case WeatherCondition.cold:
        return tr('weather.advice.veryCold');
      case WeatherCondition.mild:
        return tr('weather.advice.mild');
      case WeatherCondition.sunny:
        return tr('weather.advice.sunny');
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.cloudy:
      case WeatherCondition.any:
      default:
        return tr('weather.advice.normal');
    }
  }
} 