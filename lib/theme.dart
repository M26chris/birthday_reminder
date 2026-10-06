import 'package:flutter/material.dart';

class RemindraTheme {
  // Colors
  static const Color primaryDeep = Color(0xFF6A1B9A);      // Deep Purple
  static const Color primaryLight = Color(0xFF9C27B0);     // Light Purple
  static const Color accentGold = Color(0xFFFFC107);       // Gold
  static const Color accentAmber = Color(0xFFFF9800);      // Amber
  static const Color backgroundDark = Color(0xFF121212);   // Dark background
  static const Color backgroundLight = Color(0xFFFAFAFA);  // Light background
  static const Color cardDark = Color(0xFF1E1E1E);         // Dark card
  static const Color cardLight = Color(0xFFFFFFFF);        // Light card
  static const Color textPrimary = Color(0xFF212121);      // Dark text
  static const Color textSecondary = Color(0xFF757575);    // Gray text
  static const Color borderColor = Color(0xFFE0E0E0);      // Border
  static const Color successGreen = Color(0xFF4CAF50);     // Success
  static const Color warningRed = Color(0xFFF44336);       // Warning

  // Theme data
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDeep,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      colorScheme: ColorScheme.light(
        primary: primaryDeep,
        secondary: accentGold,
        surface: cardLight,
        error: warningRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardLight,
        indicatorColor: primaryDeep.withOpacity(0.1),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      colorScheme: ColorScheme.dark(
        primary: primaryLight,
        secondary: accentGold,
        surface: cardDark,
        error: warningRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        indicatorColor: accentGold.withOpacity(0.2),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}