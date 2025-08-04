import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Philosophy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'About PebbleBoard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Just as a penguin builds its nest one pebble at a time, PebbleBoard empowers you to gather and safeguard the valuable links you find across the web. Each saved link is a “pebble” – a piece of your curated digital world.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Our Core Philosophy: Your Content, Truly Yours.',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              children: const [
                TextSpan(
                  text: 'In an online world driven by tracking and monetization, PebbleBoard stands apart. Your boards, bookmarks, and collections are stored ',
                ),
                TextSpan(
                  text: 'only',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' on your device. We believe your digital life is private. Nothing is uploaded, synced, or shared unless ',
                ),
                TextSpan(
                  text: 'you',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' explicitly choose to. No accounts. No ads. No hidden analytics.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Key Principles:',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _BulletPoint(text: 'Private by Design: Your data never leaves your device.', theme: theme),
          _BulletPoint(text: 'Organized Your Way: Create custom boards for every topic, project, or interest.', theme: theme),
          _BulletPoint(text: 'Universal Capture: Save links effortlessly from any app or browser.', theme: theme),
          const SizedBox(height: 24),
          Text(
            'PebbleBoard: Curate your web, on your terms. Private, organized, yours.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _BulletPoint({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}