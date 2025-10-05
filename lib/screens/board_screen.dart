import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/providers/paginated_bookmarks_provider.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/providers/boards_with_thumbnails_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'dart:ui'; // Added import
import 'package:go_router/go_router.dart'; // New import
import 'package:pebble_board/utils/dialog_utils.dart';
import 'package:pebble_board/app_routes.dart'; // New import
import 'package:pebble_board/models/share_screen_extra.dart';
import 'package:pebble_board/utils/app_constants.dart'; // New import
import 'package:metadata_fetch/metadata_fetch.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pebble_board/widgets/bookmark_details_sheet.dart';

final boardProvider = FutureProvider.family<Board?, int>((ref, boardId) {
  final dao = ref.watch(boardsDaoProvider);
  return (dao.select(dao.boards)..where((b) => b.id.equals(boardId))).getSingleOrNull();
});

class BoardScreen extends ConsumerStatefulWidget {
  final int boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isMultiSelecting = false; // New state for multi-select mode
  final Set<int> _selectedBookmarkIds = {}; // New set to store selected bookmark IDs
  BookmarkSortOrder _sortOrder = BookmarkSortOrder.createdAtDesc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(paginatedBookmarksProvider(widget.boardId).notifier).setSearchQuery(_searchController.text);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedBookmarksProvider(widget.boardId).notifier).fetchNextPage();
    }
  }

  void _toggleMultiSelect(Bookmark bookmark) {
    setState(() {
      if (_selectedBookmarkIds.contains(bookmark.id)) {
        _selectedBookmarkIds.remove(bookmark.id);
      } else {
        _selectedBookmarkIds.add(bookmark.id);
      }
      _isMultiSelecting = _selectedBookmarkIds.isNotEmpty;
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelecting = false;
      _selectedBookmarkIds.clear();
    });
  }

  Future<void> _showSortDialog() async {
    final selectedOrder = await showDialog<BookmarkSortOrder>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort by'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, BookmarkSortOrder.createdAtDesc),
            child: const Text('Date Added (Newest)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, BookmarkSortOrder.createdAtAsc),
            child: const Text('Date Added (Oldest)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, BookmarkSortOrder.titleAsc),
            child: const Text('Title (A-Z)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, BookmarkSortOrder.titleDesc),
            child: const Text('Title (Z-A)'),
          ),
        ],
      ),
    );

    if (selectedOrder != null) {
      setState(() {
        _sortOrder = selectedOrder;
      });
      ref.read(paginatedBookmarksProvider(widget.boardId).notifier).setSortOrder(selectedOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksState = ref.watch(paginatedBookmarksProvider(widget.boardId));
    final boardAsyncValue = ref.watch(boardProvider(widget.boardId));
    final boardView = ref.watch(settingsProvider).boardView;

    return Scaffold(
      appBar: _isMultiSelecting
          ? _buildMultiSelectAppBar() // New: Multi-select app bar
          : AppBar(
              title: _isSearching
                   ? TextField(
                       controller: _searchController,
                       onChanged: (value) => ref.read(paginatedBookmarksProvider(widget.boardId).notifier).setSearchQuery(value),
                       decoration: const InputDecoration(
                         hintText: 'Search bookmarks...',
                         border: UnderlineInputBorder(
                           borderSide: BorderSide(color: Colors.white),
                         ),
                         enabledBorder: UnderlineInputBorder(
                           borderSide: BorderSide(color: Colors.white54),
                         ),
                         focusedBorder: UnderlineInputBorder(
                           borderSide: BorderSide(color: Colors.white),
                         ),
                         hintStyle: TextStyle(color: Colors.white70),
                         contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                       ),
                       style: const TextStyle(color: Colors.white),
                       autofocus: true,
                     )
                  : boardAsyncValue.when(
                      data: (board) => Text(board?.name ?? 'Board'),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const Text('Error'),
                    ),
              actions: [
                _isSearching
                     ? IconButton(
                         icon: const Icon(Icons.clear),
                         onPressed: () {
                           _searchController.clear();
                           ref.read(paginatedBookmarksProvider(widget.boardId).notifier).setSearchQuery('');
                           setState(() {
                             _isSearching = false;
                           });
                         },
                       )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortDialog,
                ),
                 IconButton(
                   icon: const Icon(Icons.select_all),
                   onPressed: () => setState(() => _isMultiSelecting = true),
                 ),
                 IconButton(
                   icon: const Icon(Icons.settings_outlined),
                   onPressed: () => context.push(AppRoutes.settings),
                 ),
              ],
            ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.read(paginatedBookmarksProvider(widget.boardId).notifier).fetchFirstPage();
            },
            child: _buildContent(bookmarksState, boardView),
          ),

        ],
      ),
      floatingActionButton: _isMultiSelecting ? null : FloatingActionButton(
        onPressed: () => _showAddUrlDialog(context),
        tooltip: 'Add Bookmark',
        child: const Icon(Icons.bookmark_add),
      ),
    );
  }

  AppBar _buildMultiSelectAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitMultiSelect,
      ),
      title: Text('${_selectedBookmarkIds.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context: context,
              title: 'Delete Selected Bookmarks',
              content: 'Are you sure you want to delete ${_selectedBookmarkIds.length} selected bookmarks?',
              confirmButtonText: 'Delete',
            );
            if (confirmed == true) {
              final dao = ref.read(bookmarksDaoProvider);
              await dao.deleteBookmarksByIds(_selectedBookmarkIds.toList());
              ref.read(paginatedBookmarksProvider(widget.boardId).notifier).removeBookmarksByIds(_selectedBookmarkIds.toList());
              _exitMultiSelect();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_selectedBookmarkIds.length} bookmarks deleted.')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.drive_file_move),
          onPressed: () async {
            final boards = ref.read(boardsWithThumbnailsProvider).value; // Get all boards
            if (boards == null || boards.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No other boards to move to.')),
              );
              return;
            }

            final selectedBoard = await showDialog<Board>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Move to Board'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: boards.length,
                      itemBuilder: (BuildContext context, int index) {
                        final board = boards[index].board;
                        return ListTile(
                          title: Text(board.name),
                          onTap: () {
                            Navigator.pop(dialogContext, board);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );

            if (selectedBoard != null && selectedBoard.id != widget.boardId) {
              final dao = ref.read(bookmarksDaoProvider);
              await dao.updateBookmarksBoardId(_selectedBookmarkIds.toList(), selectedBoard.id);
              ref.read(paginatedBookmarksProvider(widget.boardId).notifier).removeBookmarksByIds(_selectedBookmarkIds.toList());
              _exitMultiSelect();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_selectedBookmarkIds.length} bookmarks moved to ${selectedBoard.name}.')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildContent(PaginatedBookmarksState bookmarksState, BoardView boardView) {
    if (bookmarksState.bookmarks.isEmpty && bookmarksState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookmarksState.bookmarks.isEmpty && !bookmarksState.isLoading) {
      return _EmptyState(onAddBookmarkPressed: () => _showAddUrlDialog(context));
    }

    if (bookmarksState.error != null) {
      return Center(child: Text('Error: ${bookmarksState.error}'));
    }

    final itemCount = bookmarksState.bookmarks.length + (bookmarksState.hasMore ? 1 : 0);

    if (boardView == BoardView.grid) {
      return _buildGridView(bookmarksState, itemCount);
    } else {
      return _buildListView(bookmarksState, itemCount);
    }
  }

  Widget _buildGridView(PaginatedBookmarksState bookmarksState, int itemCount) {
    return ReorderableGridView( // Changed to ReorderableGridView.builder
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      children: bookmarksState.bookmarks.map((bookmark) {
        return ReorderableDelayedDragStartListener( // Added for drag handle
          key: ValueKey(bookmark.id), // Key is required for ReorderableListView
          index: bookmarksState.bookmarks.indexOf(bookmark),
          child: Dismissible(
            key: ValueKey(bookmark.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showConfirmationDialog(
                context: context,
                title: AppConstants.confirmDeletionDialogTitle,
                content: 'Are you sure you want to delete "${bookmark.title ?? 'this bookmark'}"?',
                confirmButtonText: 'Delete',
              );
            },
            onDismissed: (direction) {
              _deleteBookmark(bookmark);
            },
            child: _GridItem(
              bookmark: bookmark,
              onTap: () {
                if (_isMultiSelecting) {
                  _toggleMultiSelect(bookmark);
                } else {
                  _showBookmarkDetails(context, bookmark);
                }
              },
              onLongPress: () {
                _toggleMultiSelect(bookmark);
              },
              isMultiSelecting: _isMultiSelecting,
              isSelected: _selectedBookmarkIds.contains(bookmark.id),
            ),
          ), // Closing parenthesis for Dismissible
        );
      }).toList(),
      onReorder: (oldIndex, newIndex) {
        if (_isMultiSelecting) return; // Disable reorder during multi-select
        ref.read(paginatedBookmarksProvider(widget.boardId).notifier).reorderBookmarks(oldIndex, newIndex);
        _updateBookmarkPositions(); // Call a new method to update positions in DB
      },
    );
  }

  Widget _buildListView(PaginatedBookmarksState bookmarksState, int itemCount) {
    return ReorderableListView(
      scrollController: _scrollController, // Use scrollController instead of controller
      padding: const EdgeInsets.all(8.0),
      children: bookmarksState.bookmarks.map((bookmark) {
        return Dismissible(
          key: ValueKey(bookmark.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showConfirmationDialog(
              context: context,
              title: AppConstants.confirmDeletionDialogTitle,
              content: 'Are you sure you want to delete "${bookmark.title ?? 'this bookmark'}"?',
              confirmButtonText: 'Delete',
            );
          },
          onDismissed: (direction) {
            _deleteBookmark(bookmark);
          },
          child: _ListItem(
            bookmark: bookmark,
            onTap: () {
              if (_isMultiSelecting) {
                _toggleMultiSelect(bookmark);
              } else {
                _showBookmarkDetails(context, bookmark);
              }
            },
            onLongPress: () {
              _toggleMultiSelect(bookmark);
            },
            isMultiSelecting: _isMultiSelecting,
            isSelected: _selectedBookmarkIds.contains(bookmark.id),
          ),
        );
      }).toList(),
      onReorder: (oldIndex, newIndex) {
        if (_isMultiSelecting) return; // Disable reorder during multi-select
        ref.read(paginatedBookmarksProvider(widget.boardId).notifier).reorderBookmarks(oldIndex, newIndex);
        _updateBookmarkPositions(); // Call a new method to update positions in DB
      },
    );
  }

  // New method to update bookmark positions in the database
  Future<void> _updateBookmarkPositions() async {
    final bookmarks = ref.read(paginatedBookmarksProvider(widget.boardId)).bookmarks;
    final dao = ref.read(bookmarksDaoProvider);

    for (int i = 0; i < bookmarks.length; i++) {
      final bookmark = bookmarks[i];
      if (bookmark.position != i) { // Only update if position has changed
        await dao.updateBookmarkPosition(bookmark.id, i);
      }
    }
  }

  void _deleteBookmark(Bookmark bookmark) {
    ref.read(paginatedBookmarksProvider(widget.boardId).notifier).removeBookmark(bookmark.id);
    final dao = ref.read(bookmarksDaoProvider);
    dao.deleteBookmark(bookmark.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${bookmark.title ?? 'Bookmark'} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final insertedBookmarkId = await dao.insertBookmark(BookmarksCompanion.insert(
              boardId: bookmark.boardId,
              url: bookmark.url,
              domain: bookmark.domain,
              title: drift.Value(bookmark.title),
              description: drift.Value(bookmark.description),
              imageUrl: drift.Value(bookmark.imageUrl),
              createdAt: bookmark.createdAt,
            ));
            final restoredBookmark = await (dao.select(dao.bookmarks)..where((b) => b.id.equals(insertedBookmarkId))).getSingle();
            ref.read(paginatedBookmarksProvider(widget.boardId).notifier).addBookmark(restoredBookmark);
          },
        ),
      ),
    );
  }

  void _showAddUrlDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppConstants.addUrlDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                context.push(AppRoutes.share, extra: ShareScreenExtra(sharedUrl: controller.text, boardId: widget.boardId));
              }
            },
            child: const Text('Next'),
          ),
          ],
        );
      },
    );
  }

  



  void _showBookmarkDetails(BuildContext context, Bookmark bookmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make background transparent
      barrierColor: Colors.black54, // Optional: A slight tint to the barrier
      builder: (context) {
        return BackdropFilter( // Added BackdropFilter
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
          child: Container( // Container to ensure blur covers the area
            color: Colors.transparent, // Transparent so blur is visible
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                 return BookmarkDetailsSheet(
                   bookmark: bookmark,
                   boardId: widget.boardId,
                   scrollController: scrollController,
                   onDelete: () {
                     Navigator.of(context).pop();
                     _deleteBookmark(bookmark);
                   },
                 );
              },
            ),
          ),
        );
      },
    );
  }



  
}

class _GridItem extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isMultiSelecting;
  final bool isSelected;

  const _GridItem({
    required this.bookmark,
    required this.onTap,
    required this.onLongPress,
    required this.isMultiSelecting,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            _CardImage(imageUrl: bookmark.imageUrl, manualThumbnailPath: bookmark.manualThumbnailPath),
            if (isMultiSelecting)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) {},
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isMultiSelecting;
  final bool isSelected;

  const _ListItem({
    required this.bookmark,
    required this.onTap,
    required this.onLongPress,
    required this.isMultiSelecting,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: SizedBox(
          width: 60,
          height: 60,
          child: _CardImage(imageUrl: bookmark.imageUrl, manualThumbnailPath: bookmark.manualThumbnailPath),
        ),
        title: Text(bookmark.title ?? bookmark.domain, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(bookmark.domain, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: isMultiSelecting
            ? Checkbox(
                value: isSelected,
                onChanged: (val) {},
              )
            : null,
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  final String? manualThumbnailPath;
  const _CardImage({this.imageUrl, this.manualThumbnailPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio( // Added AspectRatio
      aspectRatio: 1.0, // Enforce square aspect ratio
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: manualThumbnailPath != null
            ? Image.file(
                File(manualThumbnailPath!),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              )
            : imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover, // Ensures cropping and centering
                    alignment: Alignment.center, // Explicitly center the image
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.link,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  )
                : Icon(
                    Icons.link,
                    color: theme.textTheme.bodySmall?.color,
                  ),
      ),
    );
  }
}

class _BookmarkDetailsSheet extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final ScrollController scrollController;
  final VoidCallback onDelete;

  const _BookmarkDetailsSheet({
    required this.bookmark,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  ConsumerState<_BookmarkDetailsSheet> createState() => _BookmarkDetailsSheetState();
}

class _BookmarkDetailsSheetState extends ConsumerState<_BookmarkDetailsSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _manualThumbnailPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookmark.title);
    _descriptionController = TextEditingController(text: widget.bookmark.description);
    _manualThumbnailPath = widget.bookmark.manualThumbnailPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _changeThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _manualThumbnailPath = savedImage.path;
      });
    }
  }



  Future<void> _saveChanges() async {
    final dao = ref.read(bookmarksDaoProvider);
    final titleText = _titleController.text.isEmpty ? null : _titleController.text;
    final descriptionText = _descriptionController.text.isEmpty ? null : _descriptionController.text;

    final updatedBookmarkCompanion = BookmarksCompanion(
      id: drift.Value(widget.bookmark.id),
      title: drift.Value(titleText),
      description: drift.Value(descriptionText),
      manualThumbnailPath: drift.Value(_manualThumbnailPath),
    );
    await dao.updateBookmark(updatedBookmarkCompanion);
    // Update the provider's state with the new Bookmark object (not companion)
    final updatedBookmark = widget.bookmark.copyWith(
      title: drift.Value(titleText),
      description: drift.Value(descriptionText),
      manualThumbnailPath: drift.Value(_manualThumbnailPath),
    );
    ref.read(paginatedBookmarksProvider(widget.bookmark.boardId).notifier).updateBookmark(updatedBookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24.0),
      children: [
        if (_manualThumbnailPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_manualThumbnailPath!),
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: theme.scaffoldBackgroundColor,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          )
        else if (widget.bookmark.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.bookmark.imageUrl!,
                height: 200, // Set a fixed height
                fit: BoxFit.contain, // Ensure the image fits within the height
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: theme.scaffoldBackgroundColor,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          ),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.bookmark.domain,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: null, // Allow multiple lines
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ActionChip(
              avatar: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveChanges,
            ),
            ActionChip(
              avatar: const Icon(Icons.image),
              label: const Text('Change Thumbnail'),
              onPressed: _changeThumbnail,
            ),
            ActionChip(
              avatar: const Icon(Icons.open_in_browser),
              label: const Text('Open'),
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(widget.bookmark.url))) {
                  await launchUrl(Uri.parse(widget.bookmark.url));
                }
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.copy),
              label: const Text('Copy URL'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.bookmark.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppConstants.urlCopiedMessage)),
                );
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () => SharePlus.instance.share(ShareParams(text: widget.bookmark.url)),
            ),
            ActionChip(
              avatar: Icon(Icons.delete, color: theme.colorScheme.error),
              label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              onPressed: widget.onDelete,
            ),
          ],
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddBookmarkPressed;

  const _EmptyState({required this.onAddBookmarkPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            size: 80,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 24),
          Text(
            'No bookmarks yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bookmark to this board.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add a Bookmark'),
            onPressed: onAddBookmarkPressed,
          ),
        ],
      ),
    );
  }
}