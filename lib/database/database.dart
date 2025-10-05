import 'package:drift/drift.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/database/database_native.dart' if (dart.library.html) 'package:pebble_board/database/database_web.dart';

part 'database.g.dart';

enum ThumbnailSource { auto, manual }

class ThumbnailSourceConverter extends TypeConverter<ThumbnailSource, int> {
  const ThumbnailSourceConverter();
  @override
  ThumbnailSource fromSql(int fromDb) {
    return ThumbnailSource.values[fromDb];
  }

  @override
  int toSql(ThumbnailSource value) {
    return value.index;
  }
}

enum BookmarkSortOrder {
  createdAtDesc,
  createdAtAsc,
  titleAsc,
  titleDesc,
}

class Boards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get thumbnailSource => integer().map(const ThumbnailSourceConverter()).withDefault(const Constant(0))();
  TextColumn get manualThumbnailPath => text().nullable()(); // New column for manual thumbnail path
  IntColumn get position => integer().nullable()(); // Add this line
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
  TextColumn get manualThumbnailPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer().nullable()(); // Add this line
}

@DriftDatabase(tables: [Boards, Bookmarks], daos: [BoardsDao, BookmarksDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 6; // Increment schema version

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
        if (from < 5) {
          await m.addColumn(bookmarks, bookmarks.position);
        }
        if (from < 6) { // Add migration for new 'position' column in Boards
          await m.addColumn(boards, boards.position);
        }
        if (from < 7) {
          await m.addColumn(bookmarks, bookmarks.manualThumbnailPath);
        }
      },
    );
  }
}

@DriftAccessor(tables: [Boards, Bookmarks])
class BoardsDao extends DatabaseAccessor<AppDatabase> with _$BoardsDaoMixin {
  BoardsDao(super.db);

  Stream<List<BoardWithThumbnail>> watchAllBoardsWithThumbnails() {
    final query = customSelect(
      'SELECT b.*, (SELECT bm.image_url FROM bookmarks bm WHERE bm.board_id = b.id ORDER BY bm.created_at DESC LIMIT 1) as thumbnail_url, b.thumbnail_source, b.manual_thumbnail_path FROM boards b ORDER BY b.position ASC, b.created_at DESC', // Order by position
      readsFrom: {boards, bookmarks},
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        final board = boards.map(row.data);
        final thumbnailUrl = row.read<String?>('thumbnail_url');
        final thumbnailSource = ThumbnailSource.values[row.read<int>('thumbnail_source')];
        final manualThumbnailPath = row.read<String?>('manual_thumbnail_path');
        return BoardWithThumbnail(
          board: board,
          thumbnailUrl: thumbnailUrl,
          thumbnailSource: thumbnailSource,
          manualThumbnailPath: manualThumbnailPath,
        );
      }).toList();
    });
  }

  Stream<List<Board>> watchAllBoards() => select(boards).watch();
  Future<int> insertBoard(BoardsCompanion board) => into(boards).insert(board);
  Future<int> deleteBoard(int id) => (delete(boards)..where((b) => b.id.equals(id))).go();
  Future<Board?> getBoardById(int id) {
    return (select(boards)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateBoardThumbnailSource(int boardId, ThumbnailSource source) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(thumbnailSource: Value(source)),
    );
  }

  Future<void> updateBoardManualThumbnailPath(int boardId, String? path) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(manualThumbnailPath: Value(path)),
    );
  }

  Future<void> updateBoardPosition(int boardId, int position) {
    return (update(boards)..where((b) => b.id.equals(boardId))).write(
      BoardsCompanion(position: Value(position)),
    );
  }
}

@DriftAccessor(tables: [Bookmarks])
class BookmarksDao extends DatabaseAccessor<AppDatabase> with _$BookmarksDaoMixin {
  BookmarksDao(super.db);

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

  Future<void> deleteBookmarksByIds(List<int> ids) {
    return (delete(bookmarks)..where((b) => b.id.isIn(ids))).go();
  }

  Future<void> updateBookmarksBoardId(List<int> ids, int newBoardId) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids))).write(
      BookmarksCompanion(boardId: Value(newBoardId)),
    );
  }

  Future<void> updateBookmarkPosition(int bookmarkId, int position) {
    return (update(bookmarks)..where((b) => b.id.equals(bookmarkId))).write(
      BookmarksCompanion(position: Value(position)),
    );
  }
}

