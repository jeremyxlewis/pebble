import 'package:pebble_board/database/database.dart';

class ShareScreenExtra {
  final String sharedUrl;
  final Bookmark? initialBookmark;
  final int? boardId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialImageUrl;

  ShareScreenExtra({
    required this.sharedUrl,
    this.initialBookmark,
    this.boardId,
    this.initialTitle,
    this.initialDescription,
    this.initialImageUrl,
  });
}
