import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/providers/paginated_bookmarks_provider.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui'; // Added import
import 'package:go_router/go_router.dart'; // New import

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
  final TextEditingController _searchController = TextEditingController(); // New
  bool _isSaving = false;
  bool _isSearching = false; // New

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged); // New
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged); // New
    _searchController.dispose(); // New
    super.dispose();
  }

  void _onSearchChanged() { // New
    ref.read(paginatedBookmarksProvider(widget.boardId).notifier).setSearchQuery(_searchController.text);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedBookmarksProvider(widget.boardId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksState = ref.watch(paginatedBookmarksProvider(widget.boardId));
    final boardAsyncValue = ref.watch(boardProvider(widget.boardId));
    final boardView = ref.watch(settingsProvider).boardView;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching // Conditional title/search bar
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration( // Changed to const
                  hintText: 'Search bookmarks...',
                  border: UnderlineInputBorder( // Changed border
                    borderSide: BorderSide(color: Colors.white), // White underline
                  ),
                  enabledBorder: UnderlineInputBorder( // Ensure consistent border when not focused
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder( // Stronger border when focused
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  hintStyle: TextStyle(color: Colors.white70), // White hint text
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Added padding
                ),
                style: const TextStyle(color: Colors.white), // White input text
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator( // New: Pull-to-refresh
            onRefresh: () async {
              ref.read(paginatedBookmarksProvider(widget.boardId).notifier).fetchFirstPage();
            },
            child: _buildContent(bookmarksState, boardView),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUrlDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(PaginatedBookmarksState bookmarksState, BoardView boardView) {
    if (bookmarksState.bookmarks.isEmpty && bookmarksState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookmarksState.bookmarks.isEmpty && !bookmarksState.isLoading) {
      return const _EmptyState();
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
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= bookmarksState.bookmarks.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookmark = bookmarksState.bookmarks[index];
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
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete "${bookmark.title ?? 'this bookmark'}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteBookmark(bookmark);
          },
          child: _GridItem(
            bookmark: bookmark,
            onTap: () => _showBookmarkDetails(context, bookmark),
          ),
        );
      },
    );
  }

  Widget _buildListView(PaginatedBookmarksState bookmarksState, int itemCount) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= bookmarksState.bookmarks.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        final bookmark = bookmarksState.bookmarks[index];
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
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete "${bookmark.title ?? 'this bookmark'}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteBookmark(bookmark);
          },
          child: _ListItem(
            bookmark: bookmark,
            onTap: () => _showBookmarkDetails(context, bookmark),
          ),
        );
      },
    );
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
          onPressed: () {
            dao.insertBookmark(BookmarksCompanion.insert(
              boardId: bookmark.boardId,
              url: bookmark.url,
              domain: bookmark.domain,
              title: drift.Value(bookmark.title),
              description: drift.Value(bookmark.description),
              imageUrl: drift.Value(bookmark.imageUrl),
              createdAt: bookmark.createdAt,
            ));
            ref.read(paginatedBookmarksProvider(widget.boardId).notifier).fetchFirstPage();
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
          title: const Text('Add URL'),
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
                  _saveBookmark(controller.text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveBookmark(String url) async {
    if (url.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(bookmarksDaoProvider);
      final domain = Uri.parse(url).host;
      final metadata = await MetadataFetch.extract(url);

      final newBookmark = BookmarksCompanion.insert(
        boardId: widget.boardId,
        url: url,
        domain: domain,
        title: drift.Value(metadata?.title),
        description: drift.Value(metadata?.description),
        imageUrl: drift.Value(metadata?.image),
        createdAt: DateTime.now(),
      );

      final id = await dao.insertBookmark(newBookmark);
      final savedBookmark = await (dao.select(dao.bookmarks)..where((b) => b.id.equals(id))).getSingle();

      if (mounted) {
        ref.read(paginatedBookmarksProvider(widget.boardId).notifier).addBookmark(savedBookmark);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch metadata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
                return _BookmarkDetailsSheet(
                  bookmark: bookmark,
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

  const _GridItem({required this.bookmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: _CardImage(imageUrl: bookmark.imageUrl),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;

  const _ListItem({required this.bookmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 60,
          height: 60,
          child: _CardImage(imageUrl: bookmark.imageUrl),
        ),
        title: Text(bookmark.title ?? bookmark.domain, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(bookmark.domain, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  const _CardImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio( // Added AspectRatio
      aspectRatio: 1.0, // Enforce square aspect ratio
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: imageUrl != null
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

class _BookmarkDetailsSheet extends StatelessWidget {
  final Bookmark bookmark;
  final ScrollController scrollController;
  final VoidCallback onDelete;

  const _BookmarkDetailsSheet({
    required this.bookmark,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      children: [
        if (bookmark.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                bookmark.imageUrl!,
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
        Text(
          bookmark.title ?? 'No Title',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          bookmark.domain,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        if (bookmark.description != null)
          Text(
            bookmark.description!,
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
              avatar: const Icon(Icons.edit), // New Edit chip
              label: const Text('Edit'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss current sheet
                context.push('/share', extra: bookmark); // Navigate to ShareScreen with bookmark
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.open_in_browser),
              label: const Text('Open'),
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(bookmark.url))) {
                  await launchUrl(Uri.parse(bookmark.url));
                }
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.copy),
              label: const Text('Copy URL'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: bookmark.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL Copied!')),
                );
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () => Share.share(bookmark.url),
            ),
            ActionChip(
              avatar: Icon(Icons.delete, color: theme.colorScheme.error),
              label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              onPressed: onDelete,
            ),
          ],
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'Tap the + button to add a bookmark.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
