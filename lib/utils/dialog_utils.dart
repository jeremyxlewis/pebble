import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:pebble_board/app_routes.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/models/share_screen_extra.dart';
import 'package:pebble_board/providers/database_provider.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmButtonText = 'Delete',
  String cancelButtonText = 'Cancel',
}) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmButtonText),
          ),
        ],
      );
    },
  );
}

Future<void> showAddUrlDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  Metadata? fetchedMetadata; // To store fetched metadata

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Add URL'),
        content: _AddUrlDialogContent(controller: controller, onMetadataFetched: (metadata) {
          fetchedMetadata = metadata;
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                context.push(AppRoutes.share, extra: ShareScreenExtra(
                  sharedUrl: controller.text,
                  initialTitle: fetchedMetadata?.title,
                  initialDescription: fetchedMetadata?.description,
                  initialImageUrl: fetchedMetadata?.image,
                ));
              }
            },
            child: const Text('Next'),
          ),
        ],
      );
    },
  );
}

class _AddUrlDialogContent extends StatefulWidget {
  final TextEditingController controller;
  final Function(Metadata?) onMetadataFetched;

  const _AddUrlDialogContent({required this.controller, required this.onMetadataFetched});

  @override
  State<_AddUrlDialogContent> createState() => _AddUrlDialogContentState();
}

class _AddUrlDialogContentState extends State<_AddUrlDialogContent> {
  Metadata? _metadata;
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onUrlChanged);
    super.dispose();
  }

  void _onUrlChanged() {
    _debounceTimer?.cancel();
    if (widget.controller.text.isEmpty) {
      setState(() {
        _metadata = null;
        _error = null;
        _isLoading = false;
      });
      widget.onMetadataFetched(null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _fetchMetadata(widget.controller.text);
    });
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _metadata = null;
    });
    try {
      final metadata = await MetadataFetch.extract(url).timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _metadata = metadata;
        });
        widget.onMetadataFetched(metadata);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch metadata: $e';
        });
        widget.onMetadataFetched(null);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_metadata != null && !_isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_metadata!.image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(
                      _metadata!.image!,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    ),
                  ),
                if (_metadata!.title != null)
                  Text(
                    _metadata!.title!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (_metadata!.description != null)
                  Text(_metadata!.description!),
              ],
            ),
        ],
      ),
    );
  }
}

Future<Board?> showAddBoardDialog(BuildContext context, WidgetRef ref) async {
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
                // ignore: use_build_context_synchronously
                Navigator.of(dialogContext).pop(newBoard);
              } else {
                // ignore: use_build_context_synchronously
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

