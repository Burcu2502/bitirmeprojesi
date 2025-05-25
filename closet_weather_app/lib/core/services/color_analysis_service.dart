import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorAnalysisService {
  /// Bir görseldeki baskın renkleri çıkarır
  Future<List<Color>> extractDominantColors(Uint8List imageBytes, {int maxColors = 3}) async {
    try {
      // Resmi küçük boyutta decode et (performans için)
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 150, // Daha küçük boyut
        targetHeight: 150,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Palette generator'ı çalıştır
      final paletteGenerator = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: maxColors,
      );

      final colors = <Color>[];
      
      // Dominant rengi ekle
      if (paletteGenerator.dominantColor != null) {
        colors.add(paletteGenerator.dominantColor!.color);
      }
      
      // Diğer renkleri ekle
      for (final paletteColor in paletteGenerator.colors) {
        if (colors.length >= maxColors) break;
        if (!colors.any((c) => _colorsAreSimilar(c, paletteColor))) {
          colors.add(paletteColor);
        }
      }

      // Memory temizliği
      image.dispose();
      
      return colors;
    } catch (e) {
      debugPrint('❌ Renk analizi hatası: $e');
      return [];
    }
  }
  
  /// İki rengin ne kadar benzer olduğunu kontrol eder
  bool _colorsAreSimilar(Color color1, Color color2, {double threshold = 50.0}) {
    final rDiff = (color1.red - color2.red).abs();
    final gDiff = (color1.green - color2.green).abs();
    final bDiff = (color1.blue - color2.blue).abs();
    
    return (rDiff + gDiff + bDiff) < threshold;
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