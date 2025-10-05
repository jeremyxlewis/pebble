import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/providers/boards_with_thumbnails_provider.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/providers/paginated_bookmarks_provider.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/utils/app_constants.dart';
import 'package:pebble_board/utils/dialog_utils.dart';
import 'package:pebble_board/utils/link_utils.dart';

class ShareScreen extends ConsumerStatefulWidget {
  final String sharedUrl;
  final Bookmark? initialBookmark; // New optional parameter
  final int? boardId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialImageUrl;

  const ShareScreen({
    super.key,
    required this.sharedUrl,
    this.initialBookmark,
    this.boardId,
    this.initialTitle,
    this.initialDescription,
    this.initialImageUrl,
  }); // Updated constructor

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isLoadingMetadata = true;
  String? _error;
  Board? _selectedBoard;
  bool _isSaving = false;
  late final String _sanitizedUrl;
  
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final sanitizeLinks = ref.read(settingsProvider).sanitizeLinks;
      _sanitizedUrl = sanitizeLinks ? LinkUtils.sanitizeUrl(widget.sharedUrl) : widget.sharedUrl;
      if (widget.initialBookmark != null) {
        _titleController.text = widget.initialBookmark!.title ?? '';
        _descriptionController.text = widget.initialBookmark!.description ?? '';
        _imageUrlController.text = widget.initialBookmark!.imageUrl ?? '';
        _isLoadingMetadata = false; // No need to fetch metadata for existing bookmark
        _fetchInitialBoard(); // Fetch the board object for _selectedBoard
      } else if (widget.initialTitle != null || widget.initialDescription != null || widget.initialImageUrl != null) {
        // Use pre-fetched metadata from the AddUrlDialog
        _titleController.text = widget.initialTitle ?? '';
        _descriptionController.text = widget.initialDescription ?? '';
        _imageUrlController.text = widget.initialImageUrl ?? '';
        _isLoadingMetadata = false; // Metadata already provided
      } else {
        _fetchMetadata(); // Fetch metadata if not provided
      }

      if (widget.boardId != null) {
        _fetchBoardFromId(widget.boardId!); // Pass the boardId to the new function
      }
      _isInitialized = true;
    }
  }

  Future<void> _fetchInitialBoard() async {
    if (widget.initialBookmark != null) {
      try { // Added try block
        final dao = ref.read(boardsDaoProvider);
        final board = await dao.getBoardById(widget.initialBookmark!.boardId);
        if (!mounted) return;
        setState(() {
          _selectedBoard = board;
        });
      } catch (e) {
        _error = 'Failed to fetch initial board: $e';
      }
    }
  }

  // New function to fetch board from ID
  Future<void> _fetchBoardFromId(int boardId) async {
    try {
      final dao = ref.read(boardsDaoProvider);
      final board = await dao.getBoardById(boardId);
      if (!mounted) return;
      setState(() {
        _selectedBoard = board;
      });
    } catch (e) {
      _error = 'Failed to fetch board: $e';
    }
  }

  Future<void> _fetchMetadata() async {
    if (widget.initialBookmark != null) return; // Only fetch if it's a new bookmark

    setState(() {
      _isLoadingMetadata = true;
      _error = null;
    });

    try {
      final metadata = await MetadataFetch.extract(_sanitizedUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Metadata fetch timed out'),
      );
      if (mounted) {
        _titleController.text = metadata?.title ?? '';
        _descriptionController.text = metadata?.description ?? '';
        _imageUrlController.text = metadata?.image ?? '';
      }
    } catch (e) {
      if (mounted) {
        _error = 'Failed to fetch metadata: ${e.toString()}';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMetadata = false;
        });
      }
    }
  }

  Future<void> _saveBookmark() async {
    if (_selectedBoard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.noBoardSelectedMessage)),
      );
      return;
    }

    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty && _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.provideBookmarkDetailsMessage)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(bookmarksDaoProvider);
      final domain = Uri.parse(_sanitizedUrl).host;

      if (widget.initialBookmark != null) {
        // Update existing bookmark
        final updatedBookmark = BookmarksCompanion(
          id: Value(widget.initialBookmark!.id),
          boardId: Value(_selectedBoard!.id),
          url: Value(_sanitizedUrl),
          domain: Value(domain),
          title: Value(_titleController.text.isEmpty ? null : _titleController.text),
          description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
          imageUrl: Value(_imageUrlController.text.isEmpty ? null : _imageUrlController.text),
          createdAt: Value(widget.initialBookmark!.createdAt), // Keep original creation date
        );
        final oldBoardId = widget.initialBookmark!.boardId;
        await dao.updateBookmark(updatedBookmark);
        final savedBookmark = await (dao.select(dao.bookmarks)..where((b) => b.id.equals(widget.initialBookmark!.id))).getSingle();

        if (oldBoardId != _selectedBoard!.id) {
          ref.read(paginatedBookmarksProvider(oldBoardId).notifier).removeBookmark(widget.initialBookmark!.id);
          ref.read(paginatedBookmarksProvider(_selectedBoard!.id).notifier).addBookmark(savedBookmark);
        } else {
          ref.read(paginatedBookmarksProvider(_selectedBoard!.id).notifier).updateBookmark(savedBookmark);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark updated in ${_selectedBoard!.name}')),
        );
      } else {
        // Insert new bookmark
        final newBookmark = BookmarksCompanion.insert(
          boardId: _selectedBoard!.id,
          url: _sanitizedUrl,
          domain: domain,
          title: Value(_titleController.text.isEmpty ? null : _titleController.text),
          description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
          imageUrl: Value(_imageUrlController.text.isEmpty ? null : _imageUrlController.text),
          createdAt: DateTime.now(),
        );
        final id = await dao.insertBookmark(newBookmark);
        final savedBookmark = await (dao.select(dao.bookmarks)..where((b) => b.id.equals(id))).getSingle();
        ref.read(paginatedBookmarksProvider(_selectedBoard!.id).notifier).addBookmark(savedBookmark);
        if (!mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${_selectedBoard!.name}')),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bookmark: $e')),
      );
      if (!mounted) return; // Add this check here
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsyncValue = ref.watch(boardsWithThumbnailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialBookmark != null ? 'Edit Bookmark' : 'Add Bookmark'), // Dynamic title
        // Removed actions here
      ),
      body: _isLoadingMetadata
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching URL details...'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text('Failed to load URL details: $_error. Please check the URL or enter details manually.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card( // Grouping URL and image preview
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sanitized URL:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sanitizedUrl,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 16),
                              if (_imageUrlController.text.isNotEmpty)
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                      height: 180, // Increased height for better preview
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 180,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 80,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _imageUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'Image URL',
                                  border: OutlineInputBorder(),
                                  hintText: 'Optional image URL for thumbnail',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card( // Grouping editable fields
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter a title for your bookmark',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 5, // Increased maxLines for description
                                minLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                  hintText: 'Add a description for your bookmark',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card( // Grouping board selection
                        margin: const EdgeInsets.only(bottom: 24.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save to Board:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              boardsAsyncValue.when(
                                data: (boards) {
                                  return Column(
                                    children: [
                                      DropdownButtonFormField<Board>(
                                        value: _selectedBoard,
                                        hint: const Text('Select a Board'),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onChanged: (Board? newValue) {
                                          setState(() {
                                            _selectedBoard = newValue;
                                          });
                                        },
                                        items: boards.map<DropdownMenuItem<Board>>((BoardWithThumbnail boardWithThumbnail) {
                                          return DropdownMenuItem<Board>(
                                            value: boardWithThumbnail.board,
                                            child: Text(boardWithThumbnail.board.name),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity, // Make button full width
                                        child: OutlinedButton.icon( // Changed to OutlinedButton
                                          onPressed: () async {
                                            final newBoard = await showAddBoardDialog(context, ref);
                                            if (newBoard != null) {
                                              setState(() {
                                                _selectedBoard = newBoard;
                                              });
                                            }
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Create New Board'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Center(child: Text('Error loading boards: $err')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded( // Use Expanded for buttons
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Discard'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded( // Use Expanded for buttons
                            child: ElevatedButton.icon(
                              onPressed: (_isLoadingMetadata || _isSaving || _selectedBoard == null) ? null : _saveBookmark,
                              icon: _isSaving ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                              ) : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Saving...' : (widget.initialBookmark != null ? 'Update Bookmark' : 'Save Bookmark')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
    );
  }
}
