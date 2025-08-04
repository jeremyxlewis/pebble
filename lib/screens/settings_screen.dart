import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/theme/app_theme.dart';
import 'dart:io'; // New import
import 'package:path_provider/path_provider.dart'; // New import
import 'package:path/path.dart' as p; // New import
import 'package:file_picker/file_picker.dart'; // New import

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SettingsSection(
            title: 'Appearance',
            children: [
              _ThemeModeControl(
                currentThemeMode: appSettings.themeMode,
                onChanged: (mode) => settingsNotifier.setThemeMode(mode!),
              ),
              const SizedBox(height: 24),
              _AccentColorSelector(
                selectedColor: appSettings.accentColor,
                onColorSelected: (color) => settingsNotifier.setAccentColor(color),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Boards',
            children: [
              _BoardViewControl(
                currentView: appSettings.boardView,
                onChanged: (view) => settingsNotifier.setBoardView(view!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Data Management',
            children: [
              ListTile(
                title: const Text('Export Database'),
                subtitle: const Text('Save your boards and bookmarks to a file.'),
                onTap: () => _exportDatabase(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListTile(
                title: const Text('Import Database'),
                subtitle: const Text('Load boards and bookmarks from a file (requires app restart).'),
                onTap: () => _importDatabase(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('About & Privacy'),
                subtitle: const Text('Our philosophy and how we handle data.'),
                onTap: () => context.push('/settings/about'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));

      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database file not found.')),
        );
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Database',
        fileName: 'pebble_board_backup.sqlite',
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
      );

      if (result != null) {
        final newFile = File(result); // Corrected: result is already the path string
        await dbFile.copy(newFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database exported to ${newFile.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export database: $e')),
      );
    }
  }

  static Future<void> _importDatabase(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final selectedFile = File(result.files.single.path!);
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));

        if (await dbFile.exists()) {
          await dbFile.delete(); // Delete existing database
        }

        await selectedFile.copy(dbFile.path);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database imported. Please restart the app.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import database: $e')),
      );
    }
  }
}

class _ThemeModeControl extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode?> onChanged;

  const _ThemeModeControl({required this.currentThemeMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.wb_sunny)),
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.nightlight_round)),
          ],
          selected: {currentThemeMode},
          onSelectionChanged: (newSelection) => onChanged(newSelection.first),
        ),
      ],
    );
  }
}

class _AccentColorSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _AccentColorSelector({required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
          child: Text(
            'Accent Color',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppTheme.accentColors.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = AppTheme.accentColors[index];
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BoardViewControl extends StatelessWidget {
  final BoardView currentView;
  final ValueChanged<BoardView?> onChanged;

  const _BoardViewControl({required this.currentView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Bookmark Display',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SegmentedButton<BoardView>(
          segments: const [
            ButtonSegment(value: BoardView.grid, label: Text('Grid'), icon: Icon(Icons.grid_view)),
            ButtonSegment(value: BoardView.list, label: Text('List'), icon: Icon(Icons.view_list)),
          ],
          selected: {currentView},
          onSelectionChanged: (newSelection) => onChanged(newSelection.first),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
