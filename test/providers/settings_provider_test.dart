import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebble_board/providers/settings_provider.dart';

// Simple tests without mocks for now
void main() {
  group('AppSettings', () {
    test('initial should return default values', () {
      final settings = AppSettings.initial();
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.boardView, BoardView.grid);
      expect(settings.sanitizeLinks, true);
      expect(settings.accentColor, isNotNull);
    });

    test('copyWith should update specified fields', () {
      final original = AppSettings.initial();
      final updated = original.copyWith(
        themeMode: AppThemeMode.dark,
        sanitizeLinks: false,
      );

      expect(updated.themeMode, AppThemeMode.dark);
      expect(updated.boardView, BoardView.grid); // unchanged
      expect(updated.sanitizeLinks, false);
      expect(updated.accentColor, original.accentColor); // unchanged
    });

    test('copyWith should update accentColor', () {
      final original = AppSettings.initial();
      final newColor = Colors.red;
      final updated = original.copyWith(accentColor: newColor);

      expect(updated.accentColor, newColor);
    });
  });
}