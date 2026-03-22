import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/core/storage/image_storage_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../../helpers/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ImageStorageManager storageManager;
  late Directory testDir;
  
  setUp(() async {
    // Set up fake path provider
    PathProviderPlatform.instance = FakePathProviderPlatform();
    
    storageManager = ImageStorageManager();
    
    // Create a temporary test directory
    testDir = await Directory.systemTemp.createTemp('image_storage_test_');
  });
  
  tearDown(() async {
    // Clean up test directory
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });
  
  group('ImageStorageManager', () {
    // Helper to create a minimal valid JPEG image
    Uint8List createMinimalJpeg() {
      // This is a minimal valid 1x1 pixel JPEG image
      return Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
        0x37, 0xFF, 0xD9
      ]);
    }
    
    test('saveImage creates unique filenames', () async {
      // Create a test image file
      final testImageFile = File(path.join(testDir.path, 'test_image.jpg'));
      await testImageFile.writeAsBytes(createMinimalJpeg());
      
      // Save the image twice
      final path1 = await storageManager.saveImage(testImageFile);
      final path2 = await storageManager.saveImage(testImageFile);
      
      // Verify paths are different (unique filenames)
      expect(path1, isNot(equals(path2)));
      expect(path1, contains('images'));
      expect(path2, contains('images'));
      expect(path1, endsWith('.jpg'));
      expect(path2, endsWith('.jpg'));
    });
    
    test('saveImage generates thumbnail', () async {
      // Create a test image file
      final testImageFile = File(path.join(testDir.path, 'test_image.jpg'));
      await testImageFile.writeAsBytes(createMinimalJpeg());
      
      // Save the image
      final imagePath = await storageManager.saveImage(testImageFile);
      
      // Get thumbnail path
      final thumbnailPath = storageManager.getThumbnailPath(imagePath);
      
      // Verify thumbnail path format
      expect(thumbnailPath, contains('thumbnails'));
      expect(thumbnailPath, endsWith('.jpg'));
      
      // Verify thumbnail file exists
      final thumbnailAbsolutePath = await storageManager.getImagePath(thumbnailPath);
      final thumbnailFile = File(thumbnailAbsolutePath);
      expect(await thumbnailFile.exists(), isTrue);
    });
    
    test('deleteImage removes both image and thumbnail', () async {
      // Create a test image file
      final testImageFile = File(path.join(testDir.path, 'test_image.jpg'));
      await testImageFile.writeAsBytes(createMinimalJpeg());
      
      // Save the image
      final imagePath = await storageManager.saveImage(testImageFile);
      
      // Verify image exists
      final imageAbsolutePath = await storageManager.getImagePath(imagePath);
      expect(await File(imageAbsolutePath).exists(), isTrue);
      
      // Verify thumbnail exists
      final thumbnailPath = storageManager.getThumbnailPath(imagePath);
      final thumbnailAbsolutePath = await storageManager.getImagePath(thumbnailPath);
      expect(await File(thumbnailAbsolutePath).exists(), isTrue);
      
      // Delete the image
      await storageManager.deleteImage(imagePath);
      
      // Verify both are deleted
      expect(await File(imageAbsolutePath).exists(), isFalse);
      expect(await File(thumbnailAbsolutePath).exists(), isFalse);
    });
    
    test('getImagePath resolves relative paths correctly', () async {
      final relativePath = path.join('images', 'test.jpg');
      final absolutePath = await storageManager.getImagePath(relativePath);
      
      // Verify absolute path contains the relative path
      expect(absolutePath, contains('images'));
      expect(absolutePath, endsWith('test.jpg'));
      expect(path.isAbsolute(absolutePath), isTrue);
    });
    
    test('verifyImages returns missing image paths', () async {
      // Create one test image
      final testImageFile = File(path.join(testDir.path, 'test_image.jpg'));
      await testImageFile.writeAsBytes(createMinimalJpeg());
      
      final existingPath = await storageManager.saveImage(testImageFile);
      final nonExistentPath = path.join('images', 'nonexistent.jpg');
      
      // Verify images
      final missingPaths = await storageManager.verifyImages([
        existingPath,
        nonExistentPath,
      ]);
      
      // Only the non-existent path should be in the list
      expect(missingPaths, hasLength(1));
      expect(missingPaths, contains(nonExistentPath));
      expect(missingPaths, isNot(contains(existingPath)));
    });
    
    test('getThumbnailPath returns correct thumbnail path', () {
      final imagePath = path.join('images', 'abc123.jpg');
      final thumbnailPath = storageManager.getThumbnailPath(imagePath);
      
      // Use path.join to handle platform-specific separators
      expect(thumbnailPath, equals(path.join('thumbnails', 'abc123.jpg')));
    });
    
    test('saveImage handles file system errors gracefully', () async {
      // Try to save a non-existent file
      final nonExistentFile = File(path.join(testDir.path, 'nonexistent.jpg'));
      
      expect(
        () => storageManager.saveImage(nonExistentFile),
        throwsA(isA<FileSystemException>()),
      );
    });
    
    test('deleteImage handles non-existent files gracefully', () async {
      // Try to delete a non-existent image
      final nonExistentPath = path.join('images', 'nonexistent.jpg');
      
      // Should not throw an exception
      await storageManager.deleteImage(nonExistentPath);
    });
  });
}
