import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final List<Color> accentColors = [
    const Color(0xFF7D7D7D), // Default Light Primary
    const Color(0xFFB4B4B4), // Default Dark Primary
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
  ];
  // --- Light Theme Colors ---
  static const Color _lightBackground = Color(0xFFF3F3F3); // oklch(0.9551 0 0)
  static const Color _lightForeground = Color(0xFF525252); // oklch(0.3211 0 0)
  static const Color _lightCard = Color(0xFFF7F7F7); // oklch(0.9702 0 0)
  static const Color _lightCardForeground = Color(0xFF525252); // oklch(0.3211 0 0)
  static const Color _lightPrimary = Color(0xFF7D7D7D); // oklch(0.4891 0 0)
  static const Color _lightPrimaryForeground = Color(0xFFFFFFFF); // oklch(1.0000 0 0)
  static const Color _lightSecondary = Color(0xFFE7E7E7); // oklch(0.9067 0 0)
  static const Color _lightSecondaryForeground = Color(0xFF525252); // oklch(0.3211 0 0)
  static const Color _lightMuted = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _lightMutedForeground = Color(0xFF828282); // oklch(0.5103 0 0)
  static const Color _lightAccent = Color(0xFFCDCDCD); // oklch(0.8078 0 0)
  static const Color _lightAccentForeground = Color(0xFF525252); // oklch(0.3211 0 0)
  static const Color _lightDestructive = Color(0xFFD94F4F); // oklch(0.5594 0.1900 25.8625)
  static const Color _lightDestructiveForeground = Color(0xFFFFFFFF); // oklch(1.0000 0 0)
  static const Color _lightBorder = Color(0xFFD9D9D9); // oklch(0.8576 0 0)
  static const Color _lightInput = Color(0xFFE7E7E7); // oklch(0.9067 0 0)
  static const Color _lightRing = Color(0xFF7D7D7D); // oklch(0.4891 0 0)

  // --- Dark Theme Colors ---
  static const Color _darkBackground = Color(0xFF373737); // oklch(0.2178 0 0)
  static const Color _darkForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _darkCard = Color(0xFF3E3E3E); // oklch(0.2435 0 0)
  static const Color _darkCardForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _darkPrimary = Color(0xFFB4B4B4); // oklch(0.7058 0 0)
  static const Color _darkPrimaryForeground = Color(0xFF373737); // oklch(0.2178 0 0)
  static const Color _darkSecondary = Color(0xFF4F4F4F); // oklch(0.3092 0 0)
  static const Color _darkSecondaryForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _darkMuted = Color(0xFF494949); // oklch(0.2850 0 0)
  static const Color _darkMutedForeground = Color(0xFF999999); // oklch(0.5999 0 0)
  static const Color _darkAccent = Color(0xFF5E5E5E); // oklch(0.3715 0 0)
  static const Color _darkAccentForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _darkDestructive = Color(0xFFE07A7A); // oklch(0.6591 0.1530 22.1703)
  static const Color _darkDestructiveForeground = Color(0xFFFFFFFF); // oklch(1.0000 0 0)
  static const Color _darkBorder = Color(0xFF545454); // oklch(0.3290 0 0)
  static const Color _darkInput = Color(0xFF4F4F4F); // oklch(0.3092 0 0)
  static const Color _darkRing = Color(0xFFB4B4B4); // oklch(0.7058 0 0)

  // --- OLED Dark Theme Colors ---
  static const Color _oledDarkBackground = Color(0xFF000000); // Pure black for OLED
  static const Color _oledDarkForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _oledDarkCard = Color(0xFF121212); // Slightly off-black
  static const Color _oledDarkCardForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _oledDarkPrimary = Color(0xFFB4B4B4); // oklch(0.7058 0 0)
  static const Color _oledDarkPrimaryForeground = Color(0xFFFFFFFF); // oklch(1.0000 0 0)
  static const Color _oledDarkSecondary = Color(0xFF202020); // Slightly off-black
  static const Color _oledDarkSecondaryForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _oledDarkMuted = Color(0xFF181818); // Slightly off-black
  static const Color _oledDarkMutedForeground = Color(0xFF999999); // oklch(0.5999 0 0)
  static const Color _oledDarkAccent = Color(0xFF282828); // Slightly off-black
  static const Color _oledDarkAccentForeground = Color(0xFFE1E1E1); // oklch(0.8853 0 0)
  static const Color _oledDarkDestructive = Color(0xFFE07A7A); // oklch(0.6591 0.1530 22.1703)
  static const Color _oledDarkDestructiveForeground = Color(0xFFFFFFFF); // oklch(1.0000 0 0)
  static const Color _oledDarkBorder = Color(0xFF252525); // Slightly off-black
  static const Color _oledDarkInput = Color(0xFF202020); // Slightly off-black
  static const Color _oledDarkRing = Color(0xFFB4B4B4); // oklch(0.7058 0 0)

  static const double _borderRadius = 0.35 * 16; // 0.35rem converted to Flutter's default 16px base

  static ThemeData getLightTheme() {
    return _createTheme(
      brightness: Brightness.light,
      background: _lightBackground,
      foreground: _lightForeground,
      card: _lightCard,
      cardForeground: _lightCardForeground,
      primary: _lightPrimary,
      primaryForeground: _lightPrimaryForeground,
      secondary: _lightSecondary,
      secondaryForeground: _lightSecondaryForeground,
      muted: _lightMuted,
      mutedForeground: _lightMutedForeground,
      accent: _lightAccent,
      accentForeground: _lightAccentForeground,
      destructive: _lightDestructive,
      destructiveForeground: _lightDestructiveForeground,
      border: _lightBorder,
      input: _lightInput,
      ring: _lightRing,
    );
  }

  static ThemeData getDarkTheme() {
    return _createTheme(
      brightness: Brightness.dark,
      background: _darkBackground,
      foreground: _darkForeground,
      card: _darkCard,
      cardForeground: _darkCardForeground,
      primary: _darkPrimary,
      primaryForeground: _darkPrimaryForeground,
      secondary: _darkSecondary,
      secondaryForeground: _darkSecondaryForeground,
      muted: _darkMuted,
      mutedForeground: _darkMutedForeground,
      accent: _darkAccent,
      accentForeground: _darkAccentForeground,
      destructive: _darkDestructive,
      destructiveForeground: _darkDestructiveForeground,
      border: _darkBorder,
      input: _darkInput,
      ring: _darkRing,
    );
  }

  static ThemeData getOledDarkTheme() {
    return _createTheme(
      brightness: Brightness.dark,
      background: _oledDarkBackground,
      foreground: _oledDarkForeground,
      card: _oledDarkCard,
      cardForeground: _oledDarkCardForeground,
      primary: _oledDarkPrimary,
      primaryForeground: _oledDarkPrimaryForeground,
      secondary: _oledDarkSecondary,
      secondaryForeground: _oledDarkSecondaryForeground,
      muted: _oledDarkMuted,
      mutedForeground: _oledDarkMutedForeground,
      accent: _oledDarkAccent,
      accentForeground: _oledDarkAccentForeground,
      destructive: _oledDarkDestructive,
      destructiveForeground: _oledDarkDestructiveForeground,
      border: _oledDarkBorder,
      input: _oledDarkInput,
      ring: _oledDarkRing,
    );
  }

  static ThemeData _createTheme({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color card,
    required Color cardForeground,
    required Color primary,
    required Color primaryForeground,
    required Color secondary,
    required Color secondaryForeground,
    required Color muted,
    required Color mutedForeground,
    required Color accent,
    required Color accentForeground,
    required Color destructive,
    required Color destructiveForeground,
    required Color border,
    required Color input,
    required Color ring,
  }) {
    final baseTheme = ThemeData(brightness: brightness);

    // Define text themes using Google Fonts
    final TextTheme montserratTextTheme = GoogleFonts.montserratTextTheme(baseTheme.textTheme).apply(
      bodyColor: foreground,
      displayColor: foreground,
    );
    // You can define other font themes similarly if needed for specific text styles:
    // final TextTheme georgiaTextTheme = GoogleFonts.georgiaTextTheme(baseTheme.textTheme);
    // final TextTheme firaCodeTextTheme = GoogleFonts.firaCodeTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        error: destructive,
        onError: destructiveForeground,
        surface: card,
        onSurface: cardForeground,
      ),
      textTheme: montserratTextTheme, // Defaulting to Montserrat for all text
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: montserratTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        iconTheme: IconThemeData(color: mutedForeground),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0, // Shadows will be applied via BoxShadow
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        // Applying custom shadows
        shadowColor: Colors.transparent, // Set to transparent as we use custom BoxShadow
        margin: EdgeInsets.zero, // Ensure no default margin interferes with custom shadows
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        backgroundColor: card,
        contentTextStyle: TextStyle(color: cardForeground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: destructive, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: destructive, width: 2),
        ),
        labelStyle: TextStyle(color: mutedForeground),
        hintStyle: TextStyle(color: mutedForeground),
      ),
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          elevation: 0, // Custom shadows will be applied if needed
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: montserratTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: montserratTextTheme.labelLarge,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return primary.withAlpha((0.04 * 255).round());
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: montserratTextTheme.labelLarge,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return primary.withAlpha((0.04 * 255).round());
            }
            return null;
          }),
        ),
      ),
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // Custom shadows if needed
        selectedLabelStyle: montserratTextTheme.bodySmall,
        unselectedLabelStyle: montserratTextTheme.bodySmall,
      ),
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: mutedForeground,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2.0),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        labelStyle: montserratTextTheme.labelLarge,
        unselectedLabelStyle: montserratTextTheme.labelLarge,
      ),
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: background,
        selectedTileColor: secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        titleTextStyle: montserratTextTheme.titleMedium?.copyWith(color: foreground),
        subtitleTextStyle: montserratTextTheme.bodyMedium?.copyWith(color: mutedForeground),
      ),
    );
  }
}