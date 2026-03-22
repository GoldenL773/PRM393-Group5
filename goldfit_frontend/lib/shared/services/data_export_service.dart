import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Service responsible for exporting all database tables to a JSON file.
/// 
/// Validates Requirements: 17.1, 17.2, 17.3
class DataExportService {
  final DatabaseManager _dbManager;

  DataExportService(this._dbManager);

  /// Exports all database tables to a JSON map.
  Future<Map<String, dynamic>> exportToJsonMap() async {
    final db = await _dbManager.database;
    final Map<String, dynamic> exportData = {
      'version': DatabaseConstants.databaseVersion,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final tables = [
      DatabaseConstants.tableClothingItems,
      DatabaseConstants.tableOutfits,
      DatabaseConstants.tableOutfitItems,
      DatabaseConstants.tableOutfitCalendar,
      DatabaseConstants.tableUsageHistory,
      DatabaseConstants.tableBasePhotos,
      DatabaseConstants.tableTryOnSessions,
      DatabaseConstants.tableUserPreferences,
      DatabaseConstants.tableTags,
      DatabaseConstants.tableClothingTags,
    ];

    for (final table in tables) {
      final rows = await db.query(table);
      exportData[table] = rows;
    }

    return exportData;
  }

  /// Exports the database to a JSON file and returns the file path.
  Future<String> exportToFile() async {
    final data = await exportToJsonMap();
    final jsonString = jsonEncode(data);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/goldfit_backup_$timestamp.json';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }
}
