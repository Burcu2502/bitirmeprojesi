import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorAnalysisService {
  /// Bir görseldeki gerçek renkleri çıkarır (basit ve etkili)
  Future<List<Color>> extractDominantColors(Uint8List imageBytes, {int maxColors = 3}) async {
    try {
      debugPrint('🎨 Basit renk analizi başlıyor...');
      
      // Görsel verilerini kontrol et
      if (imageBytes.isEmpty) {
        debugPrint('❌ Görsel verisi boş');
        return [];
      }
      
      // Resmi orta boyutta decode et
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 300,
        targetHeight: 300,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      debugPrint('✅ Görsel decode edildi: ${image.width}x${image.height}');

      // Palette generator ile renk analizi
      final paletteGenerator = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 12,
      );

      debugPrint('🎨 Palette oluşturuldu. Toplam renk: ${paletteGenerator.colors.length}');
      
      final colors = <Color>[];
      
      // 1. Önce dominant renk (en önemli)
      if (paletteGenerator.dominantColor != null) {
        final dominantColor = paletteGenerator.dominantColor!.color;
        if (!_isObviousBackground(dominantColor)) {
          colors.add(dominantColor);
          debugPrint('🎯 Dominant renk: ${_colorToHex(dominantColor)}');
        }
      }
      
      // 2. Vibrant renkler (canlı renkler)
      final vibrantColors = [
        paletteGenerator.vibrantColor?.color,
        paletteGenerator.lightVibrantColor?.color,
        paletteGenerator.darkVibrantColor?.color,
        paletteGenerator.mutedColor?.color,
        paletteGenerator.lightMutedColor?.color,
        paletteGenerator.darkMutedColor?.color,
      ];
      
      for (final color in vibrantColors) {
        if (color == null || colors.length >= maxColors) break;
        
        if (!_isObviousBackground(color) && !_isDuplicateColor(color, colors)) {
          colors.add(color);
          debugPrint('✨ Vibrant renk: ${_colorToHex(color)}');
        }
      }
      
      // 3. Diğer palette renkleri (en sık görülenler)
      final allColors = paletteGenerator.colors.toList();
      for (final color in allColors) {
        if (colors.length >= maxColors) break;
        
        if (!_isObviousBackground(color) && !_isDuplicateColor(color, colors)) {
          colors.add(color);
          debugPrint('🎨 Palette renk: ${_colorToHex(color)}');
        }
      }

      // Memory temizliği
      image.dispose();
      
      debugPrint('✅ Renk analizi tamamlandı. Bulunan renkler: ${colors.length}');
      return colors;
    } catch (e, stackTrace) {
      debugPrint('❌ Renk analizi hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Sadece çok açık beyaz/gri arka planları filtrele
  bool _isObviousBackground(Color color) {
    final hsl = HSLColor.fromColor(color);
    
    // Sadece çok açık ve renksiz olanları filtrele
    if (hsl.lightness > 0.9 && hsl.saturation < 0.1) {
      debugPrint('⚪ Arka plan filtrendi: ${_colorToHex(color)} (lightness: ${hsl.lightness.toStringAsFixed(2)}, saturation: ${hsl.saturation.toStringAsFixed(2)})');
      return true;
    }
    
    return false;
  }
  
  /// Rengin daha önce eklenip eklenmediğini kontrol et
  bool _isDuplicateColor(Color newColor, List<Color> existingColors) {
    for (final existing in existingColors) {
      if (_colorsAreSimilar(existing, newColor, threshold: 50)) {
        return true;
      }
    }
    return false;
  }
  
  /// Rengi hex formatına çevirir
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
  }
  
  /// İki rengin ne kadar benzer olduğunu kontrol eder
  bool _colorsAreSimilar(Color color1, Color color2, {double threshold = 60.0}) {
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