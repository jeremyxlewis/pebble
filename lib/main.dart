import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebble_board/providers/settings_provider.dart';
import 'package:pebble_board/router.dart';
import 'package:pebble_board/theme/app_theme.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
      _intentDataStreamSubscription =
          ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          final router = ref.read(routerProvider);
          router.go('/share?url=${value.first.path}');
        }
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          final router = ref.read(routerProvider);
          router.go('/share?url=${value.first.path}');
        }
      });
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

    return MaterialApp.router(
      routerConfig: router,
      title: 'PebbleBoard',
      theme: AppTheme.getLightTheme(appSettings.accentColor),
      darkTheme: AppTheme.getDarkTheme(appSettings.accentColor),
      themeMode: appSettings.themeMode,
    );
  }
}
