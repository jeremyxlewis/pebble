import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pebble_board/providers/settings_provider.dart';

import 'dart:io'; // New import
import 'package:path_provider/path_provider.dart'; // New import
import 'package:path/path.dart' as p; // New import
import 'package:file_picker/file_picker.dart'; // New import
import 'package:pebble_board/app_routes.dart'; // New import
import 'package:pebble_board/utils/app_constants.dart'; // New import

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
              ListTile(
                title: const Text('Board Thumbnail Settings'),
                subtitle: const Text('Customize how board thumbnails are displayed.'),
                onTap: () => context.push(AppRoutes.boardThumbnailSettings),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Privacy',
            children: [
              SwitchListTile(
                title: const Text('Sanitize Links'),
                subtitle: const Text('Remove tracking parameters from URLs when adding new bookmarks.'),
                value: appSettings.sanitizeLinks,
                onChanged: (value) => settingsNotifier.setSanitizeLinks(value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                onTap: () => context.push(AppRoutes.about),
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
        if (!context.mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.databaseFileNotFoundMessage)),
        );
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: AppConstants.exportDatabaseDialogTitle,
        fileName: 'pebble_board_backup.sqlite',
        type: FileType.custom,
        allowedExtensions: ['sqlite'],
      );

      if (result != null) {
        final newFile = File(result); // Corrected: result is already the path string
        await dbFile.copy(newFile.path);
        if (!context.mounted) return; // Add this check here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database exported to ${newFile.path}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return; // Add this line
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

        if (!context.mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.databaseImportedRestartMessage),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        if (!context.mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.noFileSelectedMessage)),
        );
      }
    } catch (e) {
      if (!context.mounted) return; // Add this line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import database: $e')),
      );
    }
  }
}

class _ThemeModeControl extends StatelessWidget {
  final AppThemeMode currentThemeMode;
  final ValueChanged<AppThemeMode?> onChanged;

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
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(value: AppThemeMode.light, label: Text('Light'), icon: Icon(Icons.wb_sunny)),
            ButtonSegment(value: AppThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: AppThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.nightlight_round)),
            ButtonSegment(value: AppThemeMode.oledDark, label: Text('OLED Dark'), icon: Icon(Icons.brightness_2)),
          ],
          selected: {currentThemeMode},
          onSelectionChanged: (newSelection) => onChanged(newSelection.first),
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
