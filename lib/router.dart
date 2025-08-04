import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pebble_board/screens/home_screen.dart';
import 'package:pebble_board/screens/board_screen.dart';
import 'package:pebble_board/database/database.dart'; // New import

import 'package:pebble_board/screens/about_screen.dart';
import 'package:pebble_board/screens/settings_screen.dart';
import 'package:pebble_board/screens/share_screen.dart';
import 'package:pebble_board/screens/board_thumbnail_settings_screen.dart'; // New import

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/board/:boardId',
        builder: (context, state) {
          final boardId = int.parse(state.pathParameters['boardId']!);
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: '/share',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final Bookmark? initialBookmark = state.extra as Bookmark?; // Cast extra to Bookmark?
          return ShareScreen(sharedUrl: url, initialBookmark: initialBookmark); // Pass initialBookmark
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: 'board-thumbnails',
            builder: (context, state) => const BoardThumbnailSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
