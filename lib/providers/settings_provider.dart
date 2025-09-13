import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/providers/settings_keys.dart';
import 'package:pebble_board/providers/settings_service.dart';
import 'package:pebble_board/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BoardView { grid, list }
enum AppThemeMode { light, dark, system, oledDark }

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesService(prefs);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return SettingsNotifier(settingsService);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(AppSettings.initial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeModeName = await _settingsService.getString(SettingsKeys.themeMode) ?? AppThemeMode.system.name;
    final boardViewName = await _settingsService.getString(SettingsKeys.boardView) ?? BoardView.grid.name;
    final sanitizeLinks = await _settingsService.getBool(SettingsKeys.sanitizeLinks) ?? true;
    final colorString = await _settingsService.getString(SettingsKeys.accentColor);

    Color accentColor;
    if (colorString != null) {
      final parts = colorString.split(',').map((e) => int.parse(e)).toList();
      accentColor = Color.fromARGB(parts[0], parts[1], parts[2], parts[3]);
    } else {
      accentColor = AppTheme.accentColors[0];
    }

    state = AppSettings(
      themeMode: AppThemeMode.values.firstWhere((e) => e.name == themeModeName),
      boardView: BoardView.values.firstWhere((e) => e.name == boardViewName),
      sanitizeLinks: sanitizeLinks,
      accentColor: accentColor,
    );
  }

  void setThemeMode(AppThemeMode themeMode) async {
    if (state.themeMode != themeMode) {
      state = state.copyWith(themeMode: themeMode);
      await _settingsService.setString(SettingsKeys.themeMode, themeMode.name);
    }
  }

  void setBoardView(BoardView boardView) async {
    if (state.boardView != boardView) {
      state = state.copyWith(boardView: boardView);
      await _settingsService.setString(SettingsKeys.boardView, boardView.name);
    }
  }

  void setSanitizeLinks(bool sanitizeLinks) async {
    if (state.sanitizeLinks != sanitizeLinks) {
      state = state.copyWith(sanitizeLinks: sanitizeLinks);
      await _settingsService.setBool(SettingsKeys.sanitizeLinks, sanitizeLinks);
    }
  }

  void setAccentColor(Color accentColor) async {
    if (state.accentColor != accentColor) {
      state = state.copyWith(accentColor: accentColor);
      final colorString =
          '${(accentColor.a * 255.0).round() & 0xff},${(accentColor.r * 255.0).round() & 0xff},${(accentColor.g * 255.0).round() & 0xff},${(accentColor.b * 255.0).round() & 0xff}';
      await _settingsService.setString(SettingsKeys.accentColor, colorString);
    }
  }
}

class AppSettings {
  final AppThemeMode themeMode;
  final BoardView boardView;
  final bool sanitizeLinks;
  final Color accentColor;

  AppSettings({
    required this.themeMode,
    required this.boardView,
    required this.sanitizeLinks,
    required this.accentColor,
  });

  factory AppSettings.initial() {
    return AppSettings(
      themeMode: AppThemeMode.system,
      boardView: BoardView.grid,
      sanitizeLinks: true,
      accentColor: AppTheme.accentColors[0],
    );
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    BoardView? boardView,
    bool? sanitizeLinks,
    Color? accentColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      boardView: boardView ?? this.boardView,
      sanitizeLinks: sanitizeLinks ?? this.sanitizeLinks,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
