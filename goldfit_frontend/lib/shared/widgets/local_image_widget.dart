import 'dart:io';
import 'package:flutter/material.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';

class LocalImageWidget extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const LocalImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<LocalImageWidget> createState() => _LocalImageWidgetState();
}

class _LocalImageWidgetState extends State<LocalImageWidget> {
  late Future<String> _imagePathFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(covariant LocalImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _initFuture();
    }
  }

  void _initFuture() {
    if (!widget.imagePath.startsWith('http') &&
        !widget.imagePath.startsWith('assets/') &&
        widget.imagePath.isNotEmpty) {
      _imagePathFuture = ImageStorageManager().getImagePath(widget.imagePath);
    } else {
      _imagePathFuture = Future.value(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the actual width and height to use based on constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // We need to resolve double.infinity to a concrete size if possible,
        // or allow the image to size itself naturally if constraints are unbounded.
        double? effectiveWidth = widget.width;
        double? effectiveHeight = widget.height;

        if (widget.width == double.infinity) {
          effectiveWidth = constraints.hasBoundedWidth ? constraints.maxWidth : null;
        }
        if (widget.height == double.infinity) {
          effectiveHeight = constraints.hasBoundedHeight ? constraints.maxHeight : null;
        }

        return _buildImage(effectiveWidth, effectiveHeight);
      },
    );
  }

  Widget _buildImage(double? effectiveWidth, double? effectiveHeight) {
    if (widget.imagePath.startsWith('http')) {
      return Image.network(
        widget.imagePath,
        fit: widget.fit,
        width: effectiveWidth,
        height: effectiveHeight,
        errorBuilder: (context, error, stackTrace) => const _ImageError(),
      );
    }
    
    if (widget.imagePath.startsWith('assets/')) {
      return Image.asset(
        widget.imagePath,
        fit: widget.fit,
        width: effectiveWidth,
        height: effectiveHeight,
        errorBuilder: (context, error, stackTrace) => const _ImageError(),
      );
    }

    // It's a local file stored by ImageStorageManager
    return FutureBuilder<String>(
      future: _imagePathFuture,
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
          fit: widget.fit,
          width: effectiveWidth,
          height: effectiveHeight,
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
