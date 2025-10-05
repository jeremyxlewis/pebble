import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pebble_board/database/database.dart';
import 'package:pebble_board/providers/database_provider.dart';
import 'package:pebble_board/models/board_with_thumbnail.dart';
import 'package:pebble_board/providers/boards_with_thumbnails_provider.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/utils/board_utils.dart';
import 'package:pebble_board/app_routes.dart';
import 'package:pebble_board/utils/app_constants.dart';
import 'package:pebble_board/utils/dialog_utils.dart';
import 'package:pebble_board/widgets/thumbnail_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final boardsAsyncValue = ref.watch(boardsWithThumbnailsProvider);
    final appSettings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          IconButton(
            icon: const Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: boardsAsyncValue.when(
        data: (boards) {
          final filteredBoards = boards.where((b) => b.board.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
          if (filteredBoards.isEmpty) {
            if (boards.isEmpty) {
              return const _EmptyState();
            } else {
              return Column(
                children: [
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search boards...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  const Expanded(child: Center(child: Text('No boards match your search.'))),
                ],
              );
            }
          }
          if (appSettings.boardView == BoardView.grid) {
            return Column(
              children: [
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search boards...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                Expanded(child: _GridView(boards: filteredBoards)),
              ],
            );
          } else {
            return Column(
              children: [
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search boards...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                Expanded(child: _ListView(boards: filteredBoards)),
              ],
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext bc) {
              return SafeArea(
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Add URL'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        showAddUrlDialog(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.space_dashboard),
                      title: const Text('Add Board'),
                      onTap: () async {
                        Navigator.pop(context); // Close the bottom sheet
                        final newBoard = await showAddBoardDialog(context, ref);
                        if (newBoard != null) {
                          // Optionally, navigate to the new board or show a success message
                          // For now, just refresh the boards list
                          ref.invalidate(boardsWithThumbnailsProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GridView extends ConsumerWidget {
  final List<BoardWithThumbnail> boards;

  const _GridView({required this.boards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final boardWithThumbnail = boards[index];
        return _BoardCard(
          board: boardWithThumbnail.board,
          thumbnailUrl: boardWithThumbnail.thumbnailUrl,
          thumbnailSource: boardWithThumbnail.thumbnailSource,
          manualThumbnailPath: boardWithThumbnail.manualThumbnailPath,
        );
      },
    );
  }
}

class _ListView extends ConsumerWidget {
  final List<BoardWithThumbnail> boards;

  const _ListView({required this.boards});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final boardWithThumbnail = boards[index];
        return Dismissible(
          key: ValueKey(boardWithThumbnail.board.id),
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
              content: 'Are you sure you want to delete "${boardWithThumbnail.board.name}"?',
              confirmButtonText: 'Delete',
            );
          },
          onDismissed: (direction) {
            ref.read(boardsWithThumbnailsProvider.notifier).removeBoard(boardWithThumbnail.board.id);
            ref.read(boardsDaoProvider).deleteBoard(boardWithThumbnail.board.id);
          },
          child: _BoardListTile(
            board: boardWithThumbnail.board,
            thumbnailUrl: boardWithThumbnail.thumbnailUrl,
            thumbnailSource: boardWithThumbnail.thumbnailSource,
            manualThumbnailPath: boardWithThumbnail.manualThumbnailPath,
          ),
        );
      },
    );
  }
}


class _BoardCard extends ConsumerWidget {
  final Board board;
  final String? thumbnailUrl;
  final ThumbnailSource thumbnailSource;
  final String? manualThumbnailPath;

  const _BoardCard({
    required this.board,
    this.thumbnailUrl,
    required this.thumbnailSource,
    this.manualThumbnailPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.boardPath(board.id)),
      onLongPress: () => showBoardActionsDialog(context, ref, board),
      child: Column(
        children: [
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: ThumbnailWidget(
                  thumbnailUrl: thumbnailUrl,
                  thumbnailSource: thumbnailSource,
                  manualThumbnailPath: manualThumbnailPath,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            board.name,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BoardListTile extends ConsumerWidget {
  final Board board;
  final String? thumbnailUrl;
  final ThumbnailSource thumbnailSource;
  final String? manualThumbnailPath;

  const _BoardListTile({
    required this.board,
    this.thumbnailUrl,
    required this.thumbnailSource,
    this.manualThumbnailPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            width: 50,
            height: 50,
            child: ThumbnailWidget(
              thumbnailUrl: thumbnailUrl,
              thumbnailSource: thumbnailSource,
              manualThumbnailPath: manualThumbnailPath,
              width: 50,
              height: 50,
            ),
          ),
        ),
        title: Text(board.name),
        onTap: () => context.push(AppRoutes.boardPath(board.id)),
        onLongPress: () => showBoardActionsDialog(context, ref, board),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.space_dashboard_outlined,
            size: 80,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 24),
          Text(
            'No boards yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first board to organize your links.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create a Board'),
            onPressed: () async {
              final newBoard = await showAddBoardDialog(context, ref);
              if (newBoard != null) {
                ref.invalidate(boardsWithThumbnailsProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}
