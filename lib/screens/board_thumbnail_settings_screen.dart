import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/screens/home_screen.dart'; // New import

class BoardThumbnailSettingsScreen extends ConsumerWidget {
  const BoardThumbnailSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsyncValue = ref.watch(boardsWithThumbnailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Thumbnail Settings'),
      ),
      body: boardsAsyncValue.when(
        data: (boards) {
          if (boards.isEmpty) {
            return const Center(child: Text('No boards found.'));
          }
          return ListView.builder(
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final boardWithThumbnail = boards[index];
              return ListTile(
                title: Text(boardWithThumbnail.board.name),
                subtitle: Text(
                  boardWithThumbnail.thumbnailSource == ThumbnailSource.auto
                      ? 'Automatic'
                      : 'Manual',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showThumbnailSourceDialog(
                  context,
                  ref,
                  boardWithThumbnail.board.id,
                  boardWithThumbnail.thumbnailSource,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showThumbnailSourceDialog(
    BuildContext context,
    WidgetRef ref,
    int boardId,
    ThumbnailSource currentSource,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose Thumbnail Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThumbnailSource>(
                title: const Text('Automatic (last saved bookmark)'),
                value: ThumbnailSource.auto,
                groupValue: currentSource,
                onChanged: (ThumbnailSource? value) {
                  if (value != null) {
                    ref.read(boardsDaoProvider).updateBoardThumbnailSource(boardId, value);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              RadioListTile<ThumbnailSource>(
                title: const Text('Manual (choose from gallery)'),
                value: ThumbnailSource.manual,
                groupValue: currentSource,
                onChanged: (ThumbnailSource? value) async {
                  if (value != null) {
                    ref.read(boardsDaoProvider).updateBoardThumbnailSource(boardId, value);
                    Navigator.of(dialogContext).pop();
                    if (value == ThumbnailSource.manual) {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        ref.read(boardsDaoProvider).updateBoardManualThumbnailPath(boardId, image.path);
                      }
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
