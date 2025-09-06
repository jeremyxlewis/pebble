import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pebble_board/app_routes.dart';
import 'package:pebble_board/models/share_screen_extra.dart';
import 'package:pebble_board/screens/home_screen.dart';
import 'package:pebble_board/screens/board_screen.dart';

import 'package:pebble_board/screens/about_screen.dart';
import 'package:pebble_board/screens/settings_screen.dart';
import 'package:pebble_board/screens/share_screen.dart';
import 'package:pebble_board/screens/board_thumbnail_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.board,
        builder: (context, state) {
          final boardIdString = state.pathParameters['boardId'];
          final boardId = int.tryParse(boardIdString ?? '');
          if (boardId == null) {
            return const HomeScreen();
          }
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: AppRoutes.share,
        builder: (context, state) {
          final extra = state.extra as ShareScreenExtra?;
          return ShareScreen(sharedUrl: extra?.sharedUrl ?? '', initialBookmark: extra?.initialBookmark);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.about,
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.boardThumbnailSettings,
            builder: (context, state) => const BoardThumbnailSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
