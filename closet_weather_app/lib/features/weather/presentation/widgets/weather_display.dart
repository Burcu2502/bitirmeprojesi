import 'package:flutter/material.dart';
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
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
                      'Hissedilen: ${weather.feelsLike.toStringAsFixed(1)}°C',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      weather.description.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getWeatherAdvice(weather),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  context, 
                  Icons.water_drop_outlined, 
                  'Nem',
                  '${weather.humidity}%',
                ),
                _buildWeatherDetail(
                  context, 
                  Icons.air, 
                  'Rüzgar',
                  '${weather.windSpeed} km/s',
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
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Bugün, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == today.add(const Duration(days: 1))) {
      return 'Yarın, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
      return 'Çok sıcak, hafif giyin';
    } else if (weather.isWarm) {
      return 'Sıcak, hafif giyin';
    } else if (weather.isMild) {
      return 'Ilıman, orta kalınlıkta giyin';
    } else if (weather.isCool) {
      return 'Serin, kalın giyin';
    } else if (weather.isCold) {
      return 'Soğuk, çok kalın giyin';
    }
    
    switch (weather.condition) {
      case WeatherCondition.rainy:
        return 'Yağmurlu, şemsiye al';
      case WeatherCondition.stormy:
        return 'Fırtınalı, dışarı çıkma';
      case WeatherCondition.snowy:
        return 'Karlı, kalın ve su geçirmez giyin';
      case WeatherCondition.windy:
        return 'Rüzgarlı, rüzgarlık giyin';
      case WeatherCondition.foggy:
        return 'Sisli, dikkatli ol';
      case WeatherCondition.hot:
        return 'Çok sıcak, bol su iç';
      case WeatherCondition.cold:
        return 'Çok soğuk, iyi giyinmelisin';
      case WeatherCondition.mild:
        return 'Ilıman, rahat giyinebilirsin';
      case WeatherCondition.sunny:
        return 'Güneşli, şapka ve güneş kremi kullan';
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.cloudy:
      case WeatherCondition.any:
      default:
        return 'Normal hava koşulları';
    }
  }
} 