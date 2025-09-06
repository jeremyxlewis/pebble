import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/providers/settings_keys.dart';
import 'package:pebble_board/providers/settings_service.dart';
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

    state = AppSettings(
      themeMode: AppThemeMode.values.firstWhere((e) => e.name == themeModeName),
      boardView: BoardView.values.firstWhere((e) => e.name == boardViewName),
      sanitizeLinks: sanitizeLinks,
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
}

class AppSettings {
  final AppThemeMode themeMode;
  final BoardView boardView;
  final bool sanitizeLinks;

  AppSettings({
    required this.themeMode,
    required this.boardView,
    required this.sanitizeLinks,
  });

  factory AppSettings.initial() {
    return AppSettings(
      themeMode: AppThemeMode.system,
      boardView: BoardView.grid,
      sanitizeLinks: true,
    );
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    BoardView? boardView,
    bool? sanitizeLinks,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      boardView: boardView ?? this.boardView,
      sanitizeLinks: sanitizeLinks ?? this.sanitizeLinks,
    );
  }
}
