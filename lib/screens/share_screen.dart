import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart'; // New import
import 'package:pebble_board/providers/paginated_bookmarks_provider.dart'; // New import

final boardsWithThumbnailsProvider = StreamProvider<List<BoardWithThumbnail>>((ref) {
  final dao = ref.watch(boardsDaoProvider);
  return dao.watchAllBoardsWithThumbnails();
});

class ShareScreen extends ConsumerStatefulWidget {
  final String sharedUrl;
  final Bookmark? initialBookmark; // New optional parameter

  const ShareScreen({super.key, required this.sharedUrl, this.initialBookmark}); // Updated constructor

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

  @override
  void initState() {
    super.initState();
    if (widget.initialBookmark != null) {
      _titleController.text = widget.initialBookmark!.title ?? '';
      _descriptionController.text = widget.initialBookmark!.description ?? '';
      _imageUrlController.text = widget.initialBookmark!.imageUrl ?? '';
      _isLoadingMetadata = false; // No need to fetch metadata for existing bookmark
      _fetchInitialBoard(); // Fetch the board object for _selectedBoard
    } else {
      _fetchMetadata();
    }
  }

  Future<void> _fetchInitialBoard() async {
    if (widget.initialBookmark != null) {
      final dao = ref.read(boardsDaoProvider);
      final board = await dao.getBoardById(widget.initialBookmark!.boardId);
      setState(() {
        _selectedBoard = board;
      });
    }
  }

  Future<void> _fetchMetadata() async {
    if (widget.initialBookmark != null) return; // Only fetch if it's a new bookmark

    try {
      final metadata = await MetadataFetch.extract(widget.sharedUrl);
      _titleController.text = metadata?.title ?? '';
      _descriptionController.text = metadata?.description ?? '';
      _imageUrlController.text = metadata?.image ?? '';
    } catch (e) {
      _error = 'Failed to fetch metadata: $e';
    } finally {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _saveBookmark() async {
    if (_selectedBoard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a board or create a new one.')),
      );
      return;
    }

    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty && _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least a title, description, or image URL.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dao = ref.read(bookmarksDaoProvider);
      final domain = Uri.parse(widget.sharedUrl).host;

      if (widget.initialBookmark != null) {
        // Update existing bookmark
        await dao.updateBookmark(BookmarksCompanion(
          id: Value(widget.initialBookmark!.id),
          boardId: Value(_selectedBoard!.id),
          url: Value(widget.sharedUrl),
          domain: Value(domain),
          title: Value(_titleController.text.isEmpty ? null : _titleController.text),
          description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
          imageUrl: Value(_imageUrlController.text.isEmpty ? null : _imageUrlController.text),
          createdAt: Value(widget.initialBookmark!.createdAt), // Keep original creation date
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark updated in ${_selectedBoard!.name}')),
        );
      } else {
        // Insert new bookmark
        await dao.insertBookmark(BookmarksCompanion.insert(
          boardId: _selectedBoard!.id,
          url: widget.sharedUrl,
          domain: domain,
          title: Value(_titleController.text.isEmpty ? null : _titleController.text),
          description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
          imageUrl: Value(_imageUrlController.text.isEmpty ? null : _imageUrlController.text),
          createdAt: DateTime.now(),
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${_selectedBoard!.name}')),
        );
      }

      if (mounted) {
        // Trigger refresh for the specific board's bookmarks
        ref.read(paginatedBookmarksProvider(_selectedBoard!.id).notifier).fetchFirstPage();

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error saving bookmark: $e')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Board?> _showAddBoardDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController();
    return await showDialog<Board?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Board'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Board Name',
              hintText: 'e.g. Design Inspiration',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final dao = ref.read(boardsDaoProvider);
                  final newBoardId = await dao.insertBoard(BoardsCompanion.insert(
                    name: controller.text,
                    createdAt: DateTime.now(),
                  ));
                  final newBoard = await dao.getBoardById(newBoardId);
                  Navigator.of(dialogContext).pop(newBoard);
                } else {
                  Navigator.of(dialogContext).pop(null);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
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
                                'Original URL:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.sharedUrl,
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
                                        color: Theme.of(context).colorScheme.surfaceVariant,
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
                                            final newBoard = await _showAddBoardDialog(context, ref);
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
                              label: Text(_isSaving ? 'Saving...' : (widget.initialBookmark != null ? 'Update Bookmark' : 'Save Bookmark')), // Dynamic label
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
