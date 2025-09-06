
class AppRoutes {
  static const String home = '/';
  static const String board = '/board/:boardId';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String about = 'about';
  static const String boardThumbnailSettings = 'board-thumbnails';

  static String boardPath(int boardId) => '/board/$boardId';
}
