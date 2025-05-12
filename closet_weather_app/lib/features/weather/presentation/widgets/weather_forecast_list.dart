import 'package:flutter/material.dart';
import '../../../../core/models/weather_model.dart';
import 'weather_forecast_item.dart';

class WeatherForecastList extends StatelessWidget {
  final List<WeatherModel> forecast;
  
  const WeatherForecastList({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecast.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          return WeatherForecastItem(
            weather: forecast[index],
            isToday: index == 0,
          );
        },
      ),
    );
  }
} 