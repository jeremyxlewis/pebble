import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as d; // Changed alias
import 'package:go_router/go_router.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'dart:io'; // New import for File
import 'package:cached_network_image/cached_network_image.dart'; // New import

final boardsWithThumbnailsProvider = StreamProvider<List<BoardWithThumbnail>>((ref) {
  final dao = ref.watch(boardsDaoProvider);
  return dao.watchAllBoardsWithThumbnails();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsyncValue = ref.watch(boardsWithThumbnailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PebbleBoard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: boardsAsyncValue.when(
        data: (boards) {
          if (boards.isEmpty) {
            return const _EmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0, // Changed to 1.0 for square grid items
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final boardWithThumbnail = boards[index];
              return _BoardCard(
                board: boardWithThumbnail.board,
                thumbnailUrl: boardWithThumbnail.thumbnailUrl,
                thumbnailSource: boardWithThumbnail.thumbnailSource,
                manualThumbnailPath: boardWithThumbnail.manualThumbnailPath,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUrlDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddUrlDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add URL'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () { // Removed async and result handling
                if (controller.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  context.push('/share?url=${controller.text}'); // Simply navigate
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final Board board;
  final String? thumbnailUrl;
  final ThumbnailSource thumbnailSource;
  final String? manualThumbnailPath;

  const _BoardCard({
    super.key,
    required this.board,
    this.thumbnailUrl,
    required this.thumbnailSource,
    this.manualThumbnailPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget thumbnailWidget;

    if (thumbnailSource == ThumbnailSource.auto && thumbnailUrl != null) {
      thumbnailWidget = CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(value: downloadProgress.progress),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.image_not_supported_outlined,
          color: theme.textTheme.bodySmall?.color,
        ),
      );
    } else if (thumbnailSource == ThumbnailSource.manual &&
        manualThumbnailPath != null) {
      thumbnailWidget = Image.file(
        File(manualThumbnailPath!),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          color: theme.textTheme.bodySmall?.color,
        ),
      );
    } else {
      thumbnailWidget = Icon(
        Icons.space_dashboard_outlined,
        color: theme.textTheme.bodySmall?.color,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/board/${board.id}'),
        onLongPress: () => _showBoardActionsDialog(context, ref, board),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                ),
                child: thumbnailWidget,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  board.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showRenameBoardDialog(
      BuildContext context, WidgetRef ref, Board board) async {
    final TextEditingController controller =
        TextEditingController(text: board.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Board'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Board Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty &&
                    controller.text != board.name) {
                  final dao = ref.read(boardsDaoProvider);
                  await dao
                      .update(dao.boards)
                      .replace(board.copyWith(name: controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Board renamed to "${controller.text}"')),
                  );
                  Navigator.of(dialogContext).pop();
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showBoardActionsDialog(
      BuildContext context, WidgetRef ref, Board board) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename Board'),
                onTap: () {
                  Navigator.pop(bc);
                  _showRenameBoardDialog(context, ref, board);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Board'),
                onTap: () {
                  Navigator.pop(bc);
                  _deleteBoardWithUndo(context, ref, board);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _deleteBoardWithUndo(
      BuildContext context, WidgetRef ref, Board board) async {
    final boardsDao = ref.read(boardsDaoProvider);
    final bookmarksDao = ref.read(bookmarksDaoProvider);
    final deletedBoard = board;
    final deletedBoardId = deletedBoard.id;

    final List<Bookmark> deletedBookmarks =
        await bookmarksDao.getBookmarksForBoard(deletedBoardId, limit: 999999);

    await boardsDao.deleteBoard(deletedBoardId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Board "${deletedBoard.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final newBoardId =
                await boardsDao.insertBoard(BoardsCompanion.insert(
              name: deletedBoard.name,
              createdAt: deletedBoard.createdAt,
              thumbnailSource: d.Value(deletedBoard.thumbnailSource),
              manualThumbnailPath: d.Value(deletedBoard.manualThumbnailPath),
            ));

            for (final bookmark in deletedBookmarks) {
              await bookmarksDao.insertBookmark(BookmarksCompanion.insert(
                boardId: newBoardId,
                url: bookmark.url,
                domain: bookmark.domain,
                title: d.Value(bookmark.title),
                description: d.Value(bookmark.description),
                imageUrl: d.Value(bookmark.imageUrl),
                createdAt: bookmark.createdAt,
              ));
            }
            ref.invalidate(boardsWithThumbnailsProvider);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.space_dashboard_outlined,
            size: 80,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 24),
          Text(
            'No boards yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first board.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}