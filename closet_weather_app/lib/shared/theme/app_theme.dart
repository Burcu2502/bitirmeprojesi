import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern ve platform-nötr bir renk paleti
  static const Color primaryColor = Color(0xFF42A5F5); // Modern mavi
  static const Color secondaryColor = Color(0xFFFF7597); // Pembe
  static const Color accentColor = Color(0xFF00BFA5); // Turkuaz
  static const Color backgroundColor = Color(0xFFF9FAFE); // Hafif gri tonu
  static const Color darkBackgroundColor = Color(0xFF1A1B2F); // Koyu mavi
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color infoColor = Color(0xFF29B6F6);

  // Açık tema için yardımcı renkler
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightCardColor = Color(0xFFF5F8FF);
  static const Color lightDividerColor = Color(0xFFEAECF2);
  
  // Koyu tema için yardımcı renkler
  static const Color darkSurfaceColor = Color(0xFF242639);
  static const Color darkCardColor = Color(0xFF2D2F45);
  static const Color darkDividerColor = Color(0xFF3D3F56);

  static ThemeData get lightTheme {
    // Platform bazlı değişkenler
    final bool isIOS = Platform.isIOS;
    final double cardElevation = isIOS ? 0.0 : 1.0;
    final double borderRadius = isIOS ? 16.0 : 12.0;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryColor.withOpacity(0.15),
        onPrimaryContainer: primaryColor.withOpacity(0.8),
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryColor.withOpacity(0.15),
        onSecondaryContainer: secondaryColor.withOpacity(0.8),
        tertiary: accentColor,
        onTertiary: Colors.white,
        background: backgroundColor,
        onBackground: const Color(0xFF2E3142),
        surface: lightSurfaceColor,
        onSurface: const Color(0xFF2E3142),
        surfaceVariant: lightCardColor,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // Platform bazlı AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isIOS ? lightSurfaceColor : backgroundColor,
        scrolledUnderElevation: isIOS ? 0.5 : 1.0,
        elevation: 0,
        shadowColor: isIOS ? Colors.black12 : null,
        iconTheme: const IconThemeData(color: primaryColor),
        actionsIconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF2E3142),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: const Color(0xFF2E3142),
        displayColor: const Color(0xFF2E3142),
      ),
      // İOS tarzı hafif düğmeler
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: isIOS ? 0 : 1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Zarif ve platform uyumlu input tasarımı
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isIOS ? backgroundColor : lightCardColor,
        hintStyle: TextStyle(color: const Color(0xFF2E3142).withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: isIOS ? BorderSide.none : const BorderSide(color: lightDividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: isIOS ? BorderSide.none : const BorderSide(color: lightDividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor, width: isIOS ? 1.0 : 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      cardTheme: CardTheme(
        color: lightCardColor,
        elevation: cardElevation,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: isIOS ? const BorderSide(color: lightDividerColor, width: 0.5) : BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDividerColor,
        thickness: 1,
        space: 24,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      // Platform uyumlu Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isIOS ? Colors.white : primaryColor;
          }
          return isIOS ? Colors.white : Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isIOS ? primaryColor : primaryColor.withOpacity(0.4);
          }
          return isIOS ? Colors.grey.shade300 : Colors.grey.withOpacity(0.3);
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
      ),
      // Platform uyumlu Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isIOS ? Colors.transparent : Colors.grey.shade200;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 6 : 4),
        ),
        side: BorderSide(
          width: 1.5,
          color: isIOS ? Colors.grey.shade300 : Colors.grey.shade400,
        ),
      ),
      // Dialog stili
      dialogTheme: DialogTheme(
        backgroundColor: lightSurfaceColor,
        elevation: isIOS ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceColor,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 10 : 6),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Platform bazlı değişkenler
    final bool isIOS = Platform.isIOS;
    final double cardElevation = isIOS ? 0.0 : 2.0;
    final double borderRadius = isIOS ? 16.0 : 12.0;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryColor.withOpacity(0.2),
        onPrimaryContainer: primaryColor.withOpacity(0.9),
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryColor.withOpacity(0.2),
        onSecondaryContainer: secondaryColor.withOpacity(0.9),
        tertiary: accentColor,
        onTertiary: Colors.white,
        background: darkBackgroundColor,
        onBackground: Colors.white.withOpacity(0.9),
        surface: darkSurfaceColor,
        onSurface: Colors.white.withOpacity(0.9),
        surfaceVariant: darkCardColor,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      // Platform bazlı AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isIOS ? darkSurfaceColor : darkBackgroundColor,
        scrolledUnderElevation: isIOS ? 0.5 : 2.0,
        elevation: 0,
        shadowColor: isIOS ? Colors.black26 : null,
        iconTheme: const IconThemeData(color: primaryColor),
        actionsIconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white.withOpacity(0.9),
        displayColor: Colors.white,
      ),
      // İOS tarzı hafif düğmeler
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: isIOS ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Zarif ve platform uyumlu input tasarımı
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: isIOS ? BorderSide.none : const BorderSide(color: darkDividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: isIOS ? BorderSide.none : const BorderSide(color: darkDividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor, width: isIOS ? 1.0 : 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      cardTheme: CardTheme(
        color: darkCardColor,
        elevation: cardElevation,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: isIOS ? const BorderSide(color: darkDividerColor, width: 0.5) : BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDividerColor,
        thickness: 1,
        space: 24,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      // Platform uyumlu Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isIOS ? Colors.white : primaryColor;
          }
          return isIOS ? Colors.white : Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isIOS ? primaryColor : primaryColor.withOpacity(0.4);
          }
          return isIOS ? Colors.grey.shade600 : Colors.grey.shade700;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
      ),
      // Platform uyumlu Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isIOS ? Colors.transparent : Colors.grey.shade800;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 6 : 4),
        ),
        side: BorderSide(
          width: 1.5,
          color: isIOS ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
      ),
      // Dialog stili
      dialogTheme: DialogTheme(
        backgroundColor: darkSurfaceColor,
        elevation: isIOS ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCardColor,
        contentTextStyle: TextStyle(color: Colors.black87),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 10 : 6),
        ),
      ),
    );
  }
} 