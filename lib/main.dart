import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/router.dart';
import 'package:pebble_board/theme/app_theme.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:pebble_board/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _initSharingIntents();
    }
  }

  void _initSharingIntents() {
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(_handleSharedMedia);

    ReceiveSharingIntent.instance.getInitialMedia().then(_handleSharedMedia);
  }

  void _handleSharedMedia(List<SharedMediaFile> value) {
    if (value.isNotEmpty) {
      final router = ref.read(routerProvider);
      router.go('${AppRoutes.share}?url=${value.first.path}');
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      _intentDataStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(settingsProvider);

    final theme = _getThemeData(appSettings.themeMode);

    return MaterialApp.router(
      routerConfig: router,
      title: 'PebbleBoard',
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: theme.mode,
      debugShowCheckedModeBanner: false,
    );
  }

  ({ThemeData light, ThemeData dark, ThemeMode mode}) _getThemeData(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return (
          light: AppTheme.getLightTheme(),
          dark: AppTheme.getDarkTheme(),
          mode: ThemeMode.light
        );
      case AppThemeMode.dark:
        return (
          light: AppTheme.getLightTheme(),
          dark: AppTheme.getDarkTheme(),
          mode: ThemeMode.dark
        );
      case AppThemeMode.system:
        return (
          light: AppTheme.getLightTheme(),
          dark: AppTheme.getDarkTheme(),
          mode: ThemeMode.system
        );
      case AppThemeMode.oledDark:
        return (
          light: AppTheme.getLightTheme(),
          dark: AppTheme.getOledDarkTheme(),
          mode: ThemeMode.dark
        );
    }
  }
}
