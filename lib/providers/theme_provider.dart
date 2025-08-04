import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(ThemeSettings.initial()) {
    _loadTheme();
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_themeModeKey) ?? ThemeMode.dark.name;
    final colorValue = prefs.getInt(_accentColorKey) ?? AppTheme.accentColors.first.value;

    state = ThemeSettings(
      themeMode: ThemeMode.values.firstWhere((e) => e.name == themeModeName),
      accentColor: Color(colorValue),
    );
  }

  void setThemeMode(ThemeMode themeMode) async {
    if (state.themeMode != themeMode) {
      state = state.copyWith(themeMode: themeMode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, themeMode.name);
    }
  }

  void setAccentColor(Color accentColor) async {
    if (state.accentColor != accentColor) {
      state = state.copyWith(accentColor: accentColor);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, accentColor.value);
    }
  }
}

class ThemeSettings {
  final ThemeMode themeMode;
  final Color accentColor;

  ThemeSettings({required this.themeMode, required this.accentColor});

  factory ThemeSettings.initial() {
    return ThemeSettings(
      themeMode: ThemeMode.dark, // Default to dark mode
      accentColor: AppTheme.accentColors.first,
    );
  }

  ThemeSettings copyWith({ThemeMode? themeMode, Color? accentColor}) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
