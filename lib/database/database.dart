import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pebble_board/models/board_with_thumbnail.dart';

part 'database.g.dart';

enum BookmarkSortOrder {
  createdAtDesc,
  createdAtAsc,
  titleAsc,
  titleDesc,
}

enum ThumbnailSource {
  auto,
  manual,
}

class Boards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get thumbnailSource => integer().withDefault(const Constant(0))(); // 0 for auto, 1 for manual
  TextColumn get manualThumbnailPath => text().nullable()(); // New column for manual thumbnail path
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get boardId =>
      integer().customConstraint('NOT NULL REFERENCES boards(id) ON DELETE CASCADE')();
  TextColumn get url => text()();
  TextColumn get domain => text()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Boards, Bookmarks], daos: [BoardsDao, BookmarksDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await m.addColumn(boards, boards.thumbnailSource);
        }
        if (from < 4) {
          await m.addColumn(boards, boards.manualThumbnailPath);
        }
      },
    );
  }
}

@DriftAccessor(tables: [Boards, Bookmarks])
class BoardsDao extends DatabaseAccessor<AppDatabase> with _$BoardsDaoMixin {
  BoardsDao(AppDatabase db) : super(db);

  Stream<List<BoardWithThumbnail>> watchAllBoardsWithThumbnails() {
    final query = customSelect(
      'SELECT b.*, '
      '(SELECT bm.image_url FROM bookmarks bm WHERE bm.board_id = b.id ORDER BY bm.created_at DESC LIMIT 1) as thumbnail_url, ' // Add comma here
      'b.thumbnail_source, ' // Add comma here
      'b.manual_thumbnail_path ' // Add this line to select the new column
      'FROM boards b ORDER BY b.created_at DESC',
      readsFrom: {boards, bookmarks},
    ).map((row) {
      final board = boards.map(row.data);
      final thumbnailUrl = row.read<String?>('thumbnail_url');
      final thumbnailSource = ThumbnailSource.values[row.read<int>('thumbnail_source')];
      final manualThumbnailPath = row.read<String?>('manual_thumbnail_path'); // Map the new column
      return BoardWithThumbnail(board: board, thumbnailUrl: thumbnailUrl, thumbnailSource: thumbnailSource, manualThumbnailPath: manualThumbnailPath); // Pass the new field
    });

    return query.watch();
  }

  Stream<List<Board>> watchAllBoards() => select(boards).watch();
  Future<int> insertBoard(BoardsCompanion board) => into(boards).insert(board);
  Future<int> deleteBoard(int id) => (delete(boards)..where((b) => b.id.equals(id))).go();
  Future<Board?> getBoardById(int id) {
    return (select(boards)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateBoardThumbnailSource(int boardId, ThumbnailSource source) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(thumbnailSource: Value(source.index)),
    );
  }

  Future<void> updateBoardManualThumbnailPath(int boardId, String? path) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(manualThumbnailPath: Value(path)),
    );
  }
}

@DriftAccessor(tables: [Bookmarks])
class BookmarksDao extends DatabaseAccessor<AppDatabase> with _$BookmarksDaoMixin {
  BookmarksDao(AppDatabase db) : super(db);

  Stream<List<Bookmark>> watchBookmarksInBoard(int boardId) {
    return (select(bookmarks)..where((b) => b.boardId.equals(boardId))).watch();
  }

  Future<List<Bookmark>> getBookmarksForBoard(
    int boardId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    BookmarkSortOrder sortBy = BookmarkSortOrder.createdAtDesc,
  }) {
    final query = select(bookmarks)..where((b) => b.boardId.equals(boardId));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerCaseQuery = '%${searchQuery.toLowerCase()}%';
      query.where((b) =>
          b.title.lower().like(lowerCaseQuery) |
          b.description.lower().like(lowerCaseQuery) |
          b.url.lower().like(lowerCaseQuery) |
          b.domain.lower().like(lowerCaseQuery));
    }

    switch (sortBy) {
      case BookmarkSortOrder.createdAtDesc:
        query.orderBy([(b) => OrderingTerm(expression: bookmarks.createdAt, mode: OrderingMode.desc)]);
        break;
      case BookmarkSortOrder.createdAtAsc:
        query.orderBy([(b) => OrderingTerm(expression: bookmarks.createdAt, mode: OrderingMode.asc)]);
        break;
      case BookmarkSortOrder.titleAsc:
        query.orderBy([(b) => OrderingTerm(expression: bookmarks.title, mode: OrderingMode.asc)]);
        break;
      case BookmarkSortOrder.titleDesc:
        query.orderBy([(b) => OrderingTerm(expression: bookmarks.title, mode: OrderingMode.desc)]);
        break;
    }

    query.limit(limit, offset: offset);

    return query.get();
  }

  Future<int> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(bookmark);
  Future<bool> updateBookmark(BookmarksCompanion bookmark) => // New method
      update(bookmarks).replace(bookmark);
  Future<int> deleteBookmark(int id) =>
      (delete(bookmarks)..where((b) => b.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
