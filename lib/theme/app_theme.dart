import 'package:flutter/material.dart';

// NOTE: These colors are chosen to match the Android app's look from the
// provided screenshots (dark gray surfaces, teal accents, red destructive).
// If you can share the exact hex codes from your Android theme, we can plug
// them in here 1:1. Until then, these are close matches that preserve the design.
class AppTheme {
  // Core palette (approx. matches Android design)
  static const Color _teal = Color(0xFF26A69A); // FAB / primary accent
  static const Color _tealDark = Color(0xFF1E8E82);
  static const Color _yellow = Color(0xFFF2C94C); // money value accent
  static const Color _error = Color(0xFFD32F2F); // delete buttons

  // Dark scheme bases
  static const Color _darkBg = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2C2C2C);
  static const Color _darkOutline = Color(0xFF3D3D3D);

  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _teal,
      onPrimary: Colors.white,
      secondary: _teal,
      onSecondary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _darkSurface,
      onSurface: Colors.white,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: _darkCard,
      dividerColor: _darkOutline,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: _yellow,
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: _darkOutline),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _darkOutline),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _teal),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _teal,
          side: const BorderSide(color: _teal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _teal),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _teal,
        unselectedItemColor: Colors.white70,
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _tealDark,
      onPrimary: Colors.white,
      secondary: _teal,
      onSecondary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _tealDark,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _tealDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
