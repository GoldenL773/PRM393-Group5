import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Service responsible for importing database tables from a JSON file.
/// 
/// Validates Requirements: 17.4, 17.5, 17.6
class DataImportService {
  final DatabaseManager _dbManager;

  DataImportService(this._dbManager);

  /// Imports data from a JSON file into the database.
  /// 
  /// The process runs within a single transaction, rolling back if any errors occur.
  Future<void> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file does not exist');
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await importFromJsonMap(data);
  }

  /// Imports data from a JSON map into the database.
  Future<void> importFromJsonMap(Map<String, dynamic> data) async {
    final db = await _dbManager.database;

    // Basic validation
    if (!data.containsKey('version')) {
      throw Exception('Invalid import format: missing version');
    }

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

    try {
      await db.transaction((txn) async {
        // First, clear existing tables in reverse dependency order
        for (final table in tables.reversed) {
          await txn.delete(table);
        }

        // Then insert the new data
        for (final table in tables) {
          if (data.containsKey(table)) {
            final List<dynamic> rows = data[table];
            for (final row in rows) {
              await txn.insert(
                table,
                Map<String, dynamic>.from(row),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            debugPrint('Imported ${rows.length} rows into $table');
          }
        }
      });
    } catch (e) {
      debugPrint('Import failed, rolled back: $e');
      throw Exception('Data import failed: $e');
    }
  }
}
