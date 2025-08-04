import 'package:pebble_board/database/database.dart';

class BoardWithThumbnail {
  final Board board;
  final String? thumbnailUrl;
  final ThumbnailSource thumbnailSource;
  final String? manualThumbnailPath; // New field

  BoardWithThumbnail({
    required this.board,
    this.thumbnailUrl,
    this.thumbnailSource = ThumbnailSource.auto,
    this.manualThumbnailPath,
  });
}
