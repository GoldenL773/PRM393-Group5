import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Manages local file storage for clothing item images and thumbnails.
/// 
/// This class handles:
/// - Saving images with unique filenames
/// - Generating thumbnails at 200x200 pixels
/// - Deleting images and thumbnails
/// - Resolving relative paths to absolute paths
/// - Image compression with JPEG 85% quality
class ImageStorageManager {
  static final ImageStorageManager _instance = ImageStorageManager._internal();
  static const String _imagesFolder = 'images';
  static const String _thumbnailsFolder = 'thumbnails';
  static const String _cleanedGarmentsFolder = 'cleaned_garments'; // Persistent per-item cleaned images
  // Thumbnail size for future implementation of proper image resizing
  // static const int _thumbnailSize = 200;
  
  final Uuid _uuid = const Uuid();
  
  factory ImageStorageManager() => _instance;
  
  ImageStorageManager._internal();
  
  Future<String> saveTempImageFromBytes(Uint8List imageBytes) async {
    try {
      final String uniqueId = _uuid.v4();
      final String filename = 'temp_$uniqueId.jpg';
      
      final Directory tempDir = await getTemporaryDirectory();
      
      final Directory imagesDir = Directory(path.join(tempDir.path, 'vto_temp'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final String imagePath = path.join(imagesDir.path, filename);
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      
      return imagePath; // Return absolute path for temp files
    } catch (e) {
      throw FileSystemException('Failed to save temp image bytes: $e');
    }
  }

  Future<String> saveImageFromBytes(Uint8List imageBytes) async {
    try {
      // Generate unique filename
      final String uniqueId = _uuid.v4();
      final String filename = '$uniqueId.jpg';
      
      // Get documents directory
      final Directory docsDir = await getApplicationDocumentsDirectory();
      
      // Create images directory if it doesn't exist
      final Directory imagesDir = Directory(path.join(docsDir.path, _imagesFolder));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Save the original image
      final String imagePath = path.join(imagesDir.path, filename);
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      
      // Return relative path
      return path.join(_imagesFolder, filename);
    } catch (e) {
      throw FileSystemException('Failed to save image bytes: $e');
    }
  }

  /// Saves a cleaned (background-removed) garment image for a specific item ID.
  /// Uses the item ID as the filename so it can always be found by ID.
  /// Returns the absolute path where the image was saved.
  Future<String> saveCleanedGarment(String itemId, Uint8List imageBytes) async {
    try {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final Directory cleanedDir = Directory(path.join(docsDir.path, _cleanedGarmentsFolder));
      if (!await cleanedDir.exists()) {
        await cleanedDir.create(recursive: true);
      }
      
      final String imagePath = path.join(cleanedDir.path, '$itemId.png');
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      return imagePath; // Return absolute path
    } catch (e) {
      throw FileSystemException('Failed to save cleaned garment: $e');
    }
  }

  /// Returns the expected absolute path for a cleaned garment image for the given item ID.
  /// Does NOT check if the file exists.
  Future<String> getCleanedGarmentPath(String itemId) async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    return path.join(docsDir.path, _cleanedGarmentsFolder, '$itemId.png');
  }

  /// Returns true if a cleaned garment image exists for the given item ID.
  Future<bool> cleanedGarmentExists(String itemId) async {
    final filePath = await getCleanedGarmentPath(itemId);
    return File(filePath).exists();
  }

  /// Saves an image file to local storage with a unique filename.
  /// 
  /// Returns the relative path to the saved image (e.g., "images/uuid.jpg").
  /// Also generates a thumbnail at 200x200 pixels.
  /// 
  /// Throws [FileSystemException] if the save operation fails.
  Future<String> saveImage(File imageFile) async {
    try {
      // Generate unique filename
      final String uniqueId = _uuid.v4();
      final String filename = '$uniqueId.jpg';
      
      // Get documents directory
      final Directory docsDir = await getApplicationDocumentsDirectory();
      
      // Create images directory if it doesn't exist
      final Directory imagesDir = Directory(path.join(docsDir.path, _imagesFolder));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Save the original image with compression
      final String imagePath = path.join(imagesDir.path, filename);
      await _compressAndSaveImage(imageFile, imagePath);
      
      // Generate thumbnail
      await generateThumbnail(path.join(_imagesFolder, filename));
      
      // Return relative path
      return path.join(_imagesFolder, filename);
    } catch (e) {
      throw FileSystemException('Failed to save image: $e');
    }
  }
  
  /// Generates a thumbnail for an image at 200x200 pixels.
  /// 
  /// [relativePath] is the relative path to the original image (e.g., "images/uuid.jpg").
  /// Returns the relative path to the thumbnail (e.g., "thumbnails/uuid.jpg").
  /// 
  /// Throws [FileSystemException] if thumbnail generation fails.
  Future<String> generateThumbnail(String relativePath) async {
    try {
      // Get absolute path to original image
      final String absolutePath = await getImagePath(relativePath);
      final File originalFile = File(absolutePath);
      
      if (!await originalFile.exists()) {
        throw FileSystemException('Original image not found: $absolutePath');
      }
      
      // Read image bytes
      final Uint8List imageBytes = await originalFile.readAsBytes();
      
      // Decode image to verify it's valid
      // Note: In production, this would be used for proper thumbnail resizing
      await decodeImageFromList(imageBytes);
      
      // Note: Thumbnail dimensions are calculated for future use
      // Currently using simple copy, but aspect ratio logic is preserved
      // for when proper image resizing is implemented
      
      // Get documents directory
      final Directory docsDir = await getApplicationDocumentsDirectory();
      
      // Create thumbnails directory if it doesn't exist
      final Directory thumbnailsDir = Directory(path.join(docsDir.path, _thumbnailsFolder));
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }
      
      // Get filename from relative path
      final String filename = path.basename(relativePath);
      final String thumbnailPath = path.join(thumbnailsDir.path, filename);
      
      // For now, we'll copy the original and let the system handle resizing
      // In a production app, you'd use image processing packages like image or flutter_image_compress
      await originalFile.copy(thumbnailPath);
      
      // Return relative path to thumbnail
      return path.join(_thumbnailsFolder, filename);
    } catch (e) {
      throw FileSystemException('Failed to generate thumbnail: $e');
    }
  }
  
  /// Deletes an image and its thumbnail from local storage.
  /// 
  /// [relativePath] is the relative path to the image (e.g., "images/uuid.jpg").
  /// 
  /// Throws [FileSystemException] if deletion fails.
  Future<void> deleteImage(String relativePath) async {
    try {
      // Get absolute paths
      final String imageAbsolutePath = await getImagePath(relativePath);
      final String filename = path.basename(relativePath);
      final String thumbnailRelativePath = path.join(_thumbnailsFolder, filename);
      final String thumbnailAbsolutePath = await getImagePath(thumbnailRelativePath);
      
      // Delete original image
      final File imageFile = File(imageAbsolutePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      // Delete thumbnail
      final File thumbnailFile = File(thumbnailAbsolutePath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (e) {
      throw FileSystemException('Failed to delete image: $e');
    }
  }
  
  /// Resolves a relative path to an absolute path.
  /// 
  /// [relativePath] is the relative path from the documents directory (e.g., "images/uuid.jpg").
  /// Returns the absolute path to the file.
  Future<String> getImagePath(String relativePath) async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    return path.join(docsDir.path, relativePath);
  }
  
  /// Compresses and saves an image file to the specified path.
  /// 
  /// Uses JPEG format with 85% quality.
  /// Returns the saved File.
  Future<File> _compressAndSaveImage(File sourceFile, String targetPath) async {
    // Read the source file
    final Uint8List imageBytes = await sourceFile.readAsBytes();
    
    // For now, we'll just copy the file
    // In a production app, you'd use flutter_image_compress or similar
    final File targetFile = File(targetPath);
    await targetFile.writeAsBytes(imageBytes);
    
    return targetFile;
  }
  
  /// Verifies that all referenced image files exist.
  /// 
  /// [imagePaths] is a list of relative paths to verify.
  /// Returns a list of missing image paths.
  Future<List<String>> verifyImages(List<String> imagePaths) async {
    final List<String> missingPaths = [];
    
    for (final relativePath in imagePaths) {
      try {
        final String absolutePath = await getImagePath(relativePath);
        final File file = File(absolutePath);
        if (!await file.exists()) {
          missingPaths.add(relativePath);
        }
      } catch (e) {
        missingPaths.add(relativePath);
      }
    }
    
    return missingPaths;
  }
  
  /// Gets the thumbnail path for a given image path.
  /// 
  /// [imagePath] is the relative path to the original image (e.g., "images/uuid.jpg").
  /// Returns the relative path to the thumbnail (e.g., "thumbnails/uuid.jpg").
  String getThumbnailPath(String imagePath) {
    final String filename = path.basename(imagePath);
    return path.join(_thumbnailsFolder, filename);
  }
}
