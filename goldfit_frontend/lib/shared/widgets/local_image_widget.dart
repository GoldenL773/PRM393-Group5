import 'dart:io';
import 'package:flutter/material.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';

class LocalImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const LocalImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ImageError(),
      );
    }
    
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ImageError(),
      );
    }

    // It's a local file stored by ImageStorageManager
    return FutureBuilder<String>(
      future: ImageStorageManager().getImagePath(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const _ImageError();
        }

        final file = File(snapshot.data!);
        return Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const _ImageError(),
        );
      },
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
