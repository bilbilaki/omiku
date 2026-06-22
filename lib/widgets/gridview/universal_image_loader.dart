import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UniversalImageLoader extends StatelessWidget {
  final String imagePath;

  const UniversalImageLoader({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      // Network Image via lazy Caching
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
            color: const Color(0xFFD90429),
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => const _FallbackErrorWidget(),
      );
    } else if (imagePath.startsWith('assets/')) {
      // Local App Bundle Asset
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _FallbackErrorWidget(),
      );
    } else {
      // Local storage sandbox (File system fallback)
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _FallbackErrorWidget(),
      );
    }
  }
}

class _FallbackErrorWidget extends StatelessWidget {
  const _FallbackErrorWidget();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1128),
      child: Icon(Icons.movie_creation_outlined, color: Colors.white.withOpacity(0.2), size: 40),
    );
  }
}