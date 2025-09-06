import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pebble_board/database/database.dart';

class ThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final ThumbnailSource thumbnailSource;
  final String? manualThumbnailPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    required this.thumbnailSource,
    this.manualThumbnailPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (thumbnailSource == ThumbnailSource.auto && thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        fit: fit,
        width: width,
        height: height,
        alignment: Alignment.center,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(value: downloadProgress.progress),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.image_not_supported_outlined,
          color: theme.textTheme.bodySmall?.color,
          size: 40,
        ),
      );
    } else if (thumbnailSource == ThumbnailSource.manual &&
        manualThumbnailPath != null) {
      return Image.file(
        File(manualThumbnailPath!),
        fit: fit,
        width: width,
        height: height,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          color: theme.textTheme.bodySmall?.color,
          size: 40,
        ),
      );
    } else {
      return Icon(
        Icons.space_dashboard_outlined,
        color: theme.textTheme.bodySmall?.color,
        size: 40,
      );
    }
  }
}
