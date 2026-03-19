import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake implementation of PathProviderPlatform for testing.
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  
  static Directory? _tempDir;
  
  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempDir ??= await Directory.systemTemp.createTemp('test_docs_');
    return _tempDir!.path;
  }
  
  @override
  Future<String?> getTemporaryPath() async {
    final tempDir = await Directory.systemTemp.createTemp('test_temp_');
    return tempDir.path;
  }
  
  @override
  Future<String?> getApplicationSupportPath() async {
    final supportDir = await Directory.systemTemp.createTemp('test_support_');
    return supportDir.path;
  }
  
  @override
  Future<String?> getApplicationCachePath() async {
    final cacheDir = await Directory.systemTemp.createTemp('test_cache_');
    return cacheDir.path;
  }
  
  @override
  Future<String?> getDownloadsPath() async {
    final downloadsDir = await Directory.systemTemp.createTemp('test_downloads_');
    return downloadsDir.path;
  }
  
  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }
  
  @override
  Future<String?> getExternalStoragePath() async {
    return null;
  }
  
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return null;
  }
  
  @override
  Future<String?> getLibraryPath() async {
    final libraryDir = await Directory.systemTemp.createTemp('test_library_');
    return libraryDir.path;
  }
  
  /// Clean up test directories
  static Future<void> cleanup() async {
    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
      _tempDir = null;
    }
  }
}
