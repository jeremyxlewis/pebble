import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final boardsDaoProvider = Provider<BoardsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.boardsDao;
});

final bookmarksDaoProvider = Provider<BookmarksDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.bookmarksDao;
});
