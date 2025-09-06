import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/database/database.dart'; // Import database for Board

final boardsWithThumbnailsProvider =
    StateNotifierProvider<BoardsWithThumbnailsNotifier, AsyncValue<List<BoardWithThumbnail>>>((ref) {
  return BoardsWithThumbnailsNotifier(ref.watch(boardsDaoProvider));
});

class BoardsWithThumbnailsNotifier extends StateNotifier<AsyncValue<List<BoardWithThumbnail>>> {
  final BoardsDao _boardsDao;

  BoardsWithThumbnailsNotifier(this._boardsDao) : super(const AsyncValue.loading()) {
    _boardsDao.watchAllBoardsWithThumbnails().listen((boards) {
      state = AsyncValue.data(boards);
    });
  }

  void reorderBoards(int oldIndex, int newIndex) {
    state.whenData((boards) {
      final List<BoardWithThumbnail> updatedBoards = List.from(boards);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final BoardWithThumbnail movedBoard = updatedBoards.removeAt(oldIndex);
      updatedBoards.insert(newIndex, movedBoard);

      state = AsyncValue.data(updatedBoards);

      // Update positions in the database
      _updateBoardPositionsInDb(updatedBoards);
    });
  }

  Future<void> _updateBoardPositionsInDb(List<BoardWithThumbnail> boards) async {
    for (int i = 0; i < boards.length; i++) {
      final board = boards[i].board;
      if (board.position != i) {
        await _boardsDao.updateBoardPosition(board.id, i);
      }
    }
  }

  // Add a method to remove a board from the state (for Dismissible)
  void removeBoard(int boardId) {
    state.whenData((boards) {
      state = AsyncValue.data(boards.where((b) => b.board.id != boardId).toList());
    });
  }
}
