import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:pebble_board/database/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    // Use in-memory database for testing
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Database Operations', () {
    test('should create database successfully', () async {
      final boardsDao = database.boardsDao;
      final bookmarksDao = database.bookmarksDao;

      expect(boardsDao, isNotNull);
      expect(bookmarksDao, isNotNull);
    });

    test('should insert and retrieve board', () async {
      final dao = database.boardsDao;
      final board = BoardsCompanion.insert(
        name: 'Test Board',
        createdAt: DateTime.now(),
      );

      final id = await dao.insertBoard(board);
      final retrieved = await dao.getBoardById(id);

      expect(retrieved?.name, 'Test Board');
    });

    test('should insert and retrieve bookmark', () async {
      final boardsDao = database.boardsDao;
      final bookmarksDao = database.bookmarksDao;

      // Create board first
      final board = BoardsCompanion.insert(
        name: 'Test Board',
        createdAt: DateTime.now(),
      );
      final boardId = await boardsDao.insertBoard(board);

      // Create bookmark
      final bookmark = BookmarksCompanion.insert(
        boardId: boardId,
        url: 'https://example.com',
        domain: 'example.com',
        title: Value('Test Title'),
        createdAt: DateTime.now(),
      );

      final bookmarkId = await bookmarksDao.insertBookmark(bookmark);
      final retrieved = await (bookmarksDao.select(bookmarksDao.bookmarks)..where((b) => b.id.equals(bookmarkId))).getSingle();

      expect(retrieved.url, 'https://example.com');
      expect(retrieved.title, 'Test Title');
    });
  });
}