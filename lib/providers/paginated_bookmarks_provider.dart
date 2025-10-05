import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';

import 'package:pebble_board/database/database.dart';

const int kPageSize = 20;

final paginatedBookmarksProvider = StateNotifierProvider.family<
    PaginatedBookmarksNotifier, PaginatedBookmarksState, int>((ref, boardId) {
  return PaginatedBookmarksNotifier(ref.read(bookmarksDaoProvider), boardId);
});

class PaginatedBookmarksNotifier extends StateNotifier<PaginatedBookmarksState> {
  final BookmarksDao _bookmarksDao;
  final int _boardId;
  int _offset = 0;
  String _searchQuery = ''; // New
  BookmarkSortOrder _sortOrder = BookmarkSortOrder.createdAtDesc;

  PaginatedBookmarksNotifier(this._bookmarksDao, this._boardId)
      : super(PaginatedBookmarksState.initial()) {
    // print('PaginatedBookmarksNotifier initialized for boardId: $_boardId');
    fetchFirstPage();
  }

  void setSearchQuery(String query) { // New
    if (_searchQuery == query) return;
    _searchQuery = query;
    fetchFirstPage(); // Re-fetch from start with new query
  }

  void setSortOrder(BookmarkSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    fetchFirstPage(); // Re-fetch from start with new sort order
  }

  Future<void> fetchFirstPage() async {
    _offset = 0;
    state = PaginatedBookmarksState.initial();
    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (state.isLoading && state.bookmarks.isNotEmpty) {
      // print('Already loading or has data. Skipping fetch for boardId: $_boardId');
      return;
    }
    if (!state.hasMore && state.bookmarks.isNotEmpty) {
      // print('No more data to fetch. Skipping fetch for boardId: $_boardId');
      return;
    }

    state = state.copyWith(isLoading: true);
    // print('Fetching next page for boardId: $_boardId, offset: $_offset, query: $_searchQuery');

    try {
      final newBookmarks = await _bookmarksDao.getBookmarksForBoard(
        _boardId,
        limit: kPageSize,
        offset: _offset,
        searchQuery: _searchQuery, // Pass search query
        sortBy: _sortOrder,
      );

      final hasMore = newBookmarks.length == kPageSize;
      _offset += newBookmarks.length;

      state = state.copyWith(
        bookmarks: [...state.bookmarks, ...newBookmarks],
        isLoading: false,
        hasMore: hasMore,
      );
      // print('Fetched ${newBookmarks.length} bookmarks. Total: ${state.bookmarks.length}, hasMore: $hasMore');
    } catch (e) {
      state = state.copyWith(error: e, isLoading: false);
      // print('Error fetching bookmarks for boardId $_boardId: $e');
    }
  }

  Future<void> fetchNextPage() async {
    await _fetchNextPage();
  }

  void addBookmark(Bookmark bookmark) {
    state = state.copyWith(bookmarks: [bookmark, ...state.bookmarks]);
  }

  void removeBookmark(int bookmarkId) {
    state = state.copyWith(
      bookmarks: state.bookmarks.where((b) => b.id != bookmarkId).toList(),
    );
  }

  void removeBookmarksByIds(List<int> ids) {
    state = state.copyWith(
      bookmarks: state.bookmarks.where((b) => !ids.contains(b.id)).toList(),
    );
  }

  void updateBookmark(Bookmark updatedBookmark) {
    state = state.copyWith(
      bookmarks: state.bookmarks.map((bookmark) {
        return bookmark.id == updatedBookmark.id ? updatedBookmark : bookmark;
      }).toList(),
    );
  }

  void reorderBookmarks(int oldIndex, int newIndex) {
    final List<Bookmark> updatedBookmarks = List.from(state.bookmarks);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Bookmark movedBookmark = updatedBookmarks.removeAt(oldIndex);
    updatedBookmarks.insert(newIndex, movedBookmark);

    // Update the state with the reordered list
    state = state.copyWith(bookmarks: updatedBookmarks);
  }
}

class PaginatedBookmarksState {
  final List<Bookmark> bookmarks;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  PaginatedBookmarksState({
    required this.bookmarks,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  factory PaginatedBookmarksState.initial() {
    return PaginatedBookmarksState(
      bookmarks: [],
      isLoading: true,
      hasMore: true,
    );
  }

  PaginatedBookmarksState copyWith({
    List<Bookmark>? bookmarks,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) {
    return PaginatedBookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}
