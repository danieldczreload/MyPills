import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_pills/core/config/env_config.dart';

/// Helper to resolve image paths (network, server uploads, local files, assets).
String resolveImageUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/')) {
    final baseUri = Uri.parse(EnvConfig.apiBaseUrl);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    return '$origin$path';
  }
  return path;
}

bool isRemoteImageUrl(String path) {
  return path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('/uploads/') ||
      path.startsWith('uploads/');
}

/// Unified Serene Avatar widget capable of rendering network URLs,
/// server upload paths, local files, and fallback icons gracefully.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.photoPath,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? photoPath;
  final double radius;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = radius * 2;
    final iconSize = fallbackIconSize ?? (radius * 1.1);
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHigh;
    final fgColor = foregroundColor ?? colorScheme.onSurfaceVariant;

    Widget fallback() => Container(
      width: size,
      height: size,
      color: bgColor,
      child: Center(
        child: Icon(fallbackIcon, size: iconSize, color: fgColor),
      ),
    );

    if (photoPath == null || photoPath!.trim().isEmpty) {
      return ClipOval(child: fallback());
    }

    final path = photoPath!.trim();

    Widget imageWidget;
    if (isRemoteImageUrl(path)) {
      imageWidget = Image.network(
        resolveImageUrl(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: bgColor,
            child: Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    } else if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      imageWidget = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: bgColor,
        child: imageWidget,
      ),
    );
  }
}
