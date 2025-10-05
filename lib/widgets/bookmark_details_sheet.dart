import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/providers/paginated_bookmarks_provider.dart';
import 'package:pebble_board/utils/dialog_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class BookmarkDetailsSheet extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final int boardId;
  final ScrollController scrollController;
  final VoidCallback onDelete;

  const BookmarkDetailsSheet({
    super.key,
    required this.bookmark,
    required this.boardId,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  ConsumerState<BookmarkDetailsSheet> createState() => _BookmarkDetailsSheetState();
}

class _BookmarkDetailsSheetState extends ConsumerState<BookmarkDetailsSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _manualThumbnailPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookmark.title);
    _descriptionController = TextEditingController(text: widget.bookmark.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    final updatedBookmark = widget.bookmark.copyWith(
      title: drift.Value(titleText),
      description: drift.Value(descriptionText),
      manualThumbnailPath: drift.Value(_manualThumbnailPath),
    );
    ref.read(paginatedBookmarksProvider(widget.boardId).notifier).updateBookmark(updatedBookmark);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark updated!')),
      );
    }
  }

  Future<void> _changeThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _manualThumbnailPath = savedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Bookmark',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.bookmark.domain,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
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
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
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
                  // Assuming Clipboard is imported
                  // Clipboard.setData(ClipboardData(text: widget.bookmark.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copied!')),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () {
                  // Share.share(widget.bookmark.url);
                },
              ),
              ActionChip(
                avatar: Icon(Icons.delete, color: theme.colorScheme.error),
                label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}