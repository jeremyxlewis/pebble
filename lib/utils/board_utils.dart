import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/boards_with_thumbnails_provider.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:drift/drift.dart' as d;

Future<void> showBoardActionsDialog(
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

Future<void> _showRenameBoardDialog(
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
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(                  SnackBar(                      content:                          Text('Board renamed to "${controller.text}"')),                );
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

Future<void> _deleteBoardWithUndo(
    BuildContext context, WidgetRef ref, Board board) async {
  final boardsDao = ref.read(boardsDaoProvider);
  final bookmarksDao = ref.read(bookmarksDaoProvider);
  final deletedBoard = board;
  final deletedBoardId = deletedBoard.id;

  final List<Bookmark> deletedBookmarks =
      await bookmarksDao.getBookmarksForBoard(deletedBoardId, limit: 999999);

  await boardsDao.deleteBoard(deletedBoardId);

  if (!context.mounted) return;
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