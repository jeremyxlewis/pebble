import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Curated list of modern accent colors
  static const List<Color> accentColors = [
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFFFF2D55), // Pink
    Color(0xFF5856D6), // Indigo
    Color(0xFF00A2B8), // Teal
  ];

  // --- Light Theme ---
  static const Color _lightBackground = Color(0xFFF5F5F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1D1D1F);
  static const Color _lightTextSecondary = Color(0xFF6E6E73);

  // --- Dark Theme ---
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkTextPrimary = Color(0xFFEAEAEB);
  static const Color _darkTextSecondary = Color(0xFF8A8A8E);

  static ThemeData getLightTheme(Color accentColor) {
    return _createTheme(
      brightness: Brightness.light,
      backgroundColor: _lightBackground,
      surfaceColor: _lightSurface,
      textColor: _lightTextPrimary,
      textSecondaryColor: _lightTextSecondary,
      accentColor: accentColor,
    );
  }

  static ThemeData getDarkTheme(Color accentColor) {
    return _createTheme(
      brightness: Brightness.dark,
      backgroundColor: _darkBackground,
      surfaceColor: _darkSurface,
      textColor: _darkTextPrimary,
      textSecondaryColor: _darkTextSecondary,
      accentColor: accentColor,
    );
  }

  static ThemeData _createTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondaryColor,
    required Color accentColor,
  }) {
    final baseTheme = ThemeData(brightness: brightness);
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return baseTheme.copyWith(
      primaryColor: accentColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: brightness,
        background: backgroundColor,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textSecondaryColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(color: textColor),
      ),
    );
  }
}