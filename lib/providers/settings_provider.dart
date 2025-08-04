import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pebble_board/theme/app_theme.dart';

enum BoardView { grid, list }

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings.initial()) {
    _loadSettings();
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _boardViewKey = 'board_view';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_themeModeKey) ?? ThemeMode.dark.name;
    final colorValue = prefs.getInt(_accentColorKey) ?? AppTheme.accentColors.first.value;
    final boardViewName = prefs.getString(_boardViewKey) ?? BoardView.grid.name;

    state = AppSettings(
      themeMode: ThemeMode.values.firstWhere((e) => e.name == themeModeName),
      accentColor: Color(colorValue),
      boardView: BoardView.values.firstWhere((e) => e.name == boardViewName),
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

  void setBoardView(BoardView boardView) async {
    if (state.boardView != boardView) {
      state = state.copyWith(boardView: boardView);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_boardViewKey, boardView.name);
    }
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final BoardView boardView;

  AppSettings({
    required this.themeMode,
    required this.accentColor,
    required this.boardView,
  });

  factory AppSettings.initial() {
    return AppSettings(
      themeMode: ThemeMode.dark,
      accentColor: AppTheme.accentColors.first,
      boardView: BoardView.grid, // Default to grid view
    );
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    BoardView? boardView,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      boardView: boardView ?? this.boardView,
    );
  }
}
