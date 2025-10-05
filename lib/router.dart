import 'package:flutter/material.dart';
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

import 'package:pebble_board/screens/onboarding_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (BuildContext context, GoRouterState state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      final isGoingToOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!hasSeenOnboarding && !isGoingToOnboarding) {
        return AppRoutes.onboarding;
      } else if (hasSeenOnboarding && isGoingToOnboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
       GoRoute(
         path: AppRoutes.board,
         builder: (context, state) {
           final boardIdString = state.pathParameters['boardId'];
           final boardId = int.tryParse(boardIdString ?? '');
           if (boardId == null) {
             // Show error screen instead of falling back to HomeScreen
             return Scaffold(
               appBar: AppBar(title: const Text('Error')),
               body: const Center(
                 child: Text('Invalid board ID. Please check the URL.'),
               ),
             );
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
