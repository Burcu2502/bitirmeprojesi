import 'package:flutter/material.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/models/outfit_model.dart';

class WeatherForecastItem extends StatelessWidget {
  final WeatherModel weather;
  final bool isToday;
  
  const WeatherForecastItem({
    super.key,
    required this.weather,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = _getDayName(weather.timestamp);
    
    return Container(
      width: 120,
      height: 170,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _getWeatherIcon(weather.condition),
            const SizedBox(height: 8),
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                weather.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck.compareTo(today) == 0) {
      return 'Bugün';
    } else if (dateToCheck.compareTo(tomorrow) == 0) {
      return 'Yarın';
    } else {
      final weekDay = date.weekday;
      switch (weekDay) {
        case 1:
          return 'Pazartesi';
        case 2:
          return 'Salı';
        case 3:
          return 'Çarşamba';
        case 4:
          return 'Perşembe';
        case 5:
          return 'Cuma';
        case 6:
          return 'Cumartesi';
        case 7:
          return 'Pazar';
        default:
          return '';
      }
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
      size: 32,
      color: color,
    );
  }
} 