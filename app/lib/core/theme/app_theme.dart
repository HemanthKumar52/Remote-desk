import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFF007AFF);
  static const secondaryColor = Color(0xFF5856D6);
  static const successColor = Color(0xFF34C759);
  static const warningColor = Color(0xFFFF9500);
  static const errorColor = Color(0xFFFF3B30);

  // Light Theme Colors
  static const lightBackground = Color(0xFFF2F2F7);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF1C1C1E);
  static const lightTextSecondary = Color(0xFF8E8E93);

  // Dark Theme Colors
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkText = Colors.white;
  static const darkTextSecondary = Color(0xFF8E8E93);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          color: lightText,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          color: lightText,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          color: lightTextSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          color: darkText,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          color: darkText,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          color: darkTextSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Glassmorphism decoration
class GlassmorphicDecoration extends BoxDecoration {
  GlassmorphicDecoration({
    double borderRadius = 16,
    Color? color,
  }) : super(
          color: color ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        );
}
