import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorAnalysisService {
  /// Bir görseldeki baskın renkleri çıkarır
  Future<List<Color>> extractDominantColors(Uint8List imageBytes, {int maxColors = 5}) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        MemoryImage(imageBytes),
        maximumColorCount: maxColors,
      );

      final List<Color> colors = [];
      
      if (paletteGenerator.dominantColor != null) {
        colors.add(paletteGenerator.dominantColor!.color);
      }
      
      for (var swatch in paletteGenerator.paletteColors) {
        // Önceki renklerle benzer olmasın
        if (!_isColorSimilar(swatch.color, colors)) {
          colors.add(swatch.color);
        }
        
        if (colors.length >= maxColors) break;
      }
      
      return colors;
    } catch (e) {
      return [Colors.grey]; // Hata durumunda gri döndür
    }
  }
  
  /// İki rengin ne kadar benzer olduğunu kontrol eder
  bool _isColorSimilar(Color newColor, List<Color> existingColors, {double threshold = 50.0}) {
    for (var color in existingColors) {
      final double distance = _calculateColorDistance(newColor, color);
      if (distance < threshold) {
        return true;
      }
    }
    return false;
  }
  
  /// İki renk arasındaki mesafeyi hesaplar (Euclidean distance)
  double _calculateColorDistance(Color c1, Color c2) {
    final double rDiff = (c1.red - c2.red).abs().toDouble();
    final double gDiff = (c1.green - c2.green).abs().toDouble();
    final double bDiff = (c1.blue - c2.blue).abs().toDouble();
    
    return (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }
  
  /// Renk uyumu için öneriler sunar (Tamamlayıcı, Üçlü uyum, vb.)
  List<List<Color>> getColorHarmonies(Color baseColor) {
    final Map<String, List<Color>> harmonies = {
      'complementary': _getComplementaryColors(baseColor),
      'triadic': _getTriadicColors(baseColor),
      'analogous': _getAnalogousColors(baseColor),
      'monochromatic': _getMonochromaticColors(baseColor),
    };
    
    return harmonies.values.toList();
  }
  
  /// Tamamlayıcı renk
  List<Color> _getComplementaryColors(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor complementary = hslColor.withHue((hslColor.hue + 180) % 360);
    
    return [baseColor, complementary.toColor()];
  }
  
  /// Üçlü uyumlu renkler
  List<Color> _getTriadicColors(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor color1 = hslColor.withHue((hslColor.hue + 120) % 360);
    final HSLColor color2 = hslColor.withHue((hslColor.hue + 240) % 360);
    
    return [baseColor, color1.toColor(), color2.toColor()];
  }
  
  /// Analog renkler
  List<Color> _getAnalogousColors(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor color1 = hslColor.withHue((hslColor.hue + 30) % 360);
    final HSLColor color2 = hslColor.withHue((hslColor.hue - 30) % 360);
    
    return [color2.toColor(), baseColor, color1.toColor()];
  }
  
  /// Monokromatik renkler
  List<Color> _getMonochromaticColors(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    
    final List<Color> colors = [];
    for (double i = 0.2; i <= 1.0; i += 0.2) {
      colors.add(hslColor.withLightness(i).toColor());
    }
    
    return colors;
  }
  
  /// Cilt tonuna göre uyumlu renkler önerir
  List<Color> getColorsForSkinTone(String skinTone) {
    switch (skinTone.toLowerCase()) {
      case 'fair':
      case 'açık':
        return [
          Colors.indigo,
          Colors.green.shade800,
          Colors.red.shade900,
          Colors.purple.shade900,
          Colors.brown.shade700,
        ];
        
      case 'medium':
      case 'orta':
        return [
          Colors.blue.shade700,
          Colors.green.shade600,
          Colors.orange.shade300,
          Colors.purple.shade300,
          Colors.amber.shade700,
        ];
        
      case 'tan':
      case 'buğday':
        return [
          Colors.teal,
          Colors.redAccent,
          Colors.green.shade800,
          Colors.indigoAccent,
          Colors.brown,
        ];
        
      case 'dark':
      case 'koyu':
        return [
          Colors.amber.shade600,
          Colors.pink.shade300,
          Colors.tealAccent,
          Colors.red.shade600,
          Colors.lightGreen,
        ];
        
      default:
        return [
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.purple,
          Colors.orange,
        ];
    }
  }
} 