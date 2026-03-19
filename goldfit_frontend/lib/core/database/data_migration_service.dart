import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Service responsible for migrating data from MockDataProvider to SQLite.
/// 
/// Runs once when the application starts if the migration flag is not set.
/// Validates Requirements: 12.1, 12.2, 12.3, 12.4
class DataMigrationService {
  final DatabaseManager _dbManager;
  final ClothingRepository _clothingRepository;
  final OutfitRepository _outfitRepository;
  
  static const String _migrationKey = 'mock_data_migrated';

  DataMigrationService(
    this._dbManager,
    this._clothingRepository,
    this._outfitRepository,
  );

  /// Checks if migration has been completed.
  Future<bool> hasMigrated() async {
    final db = await _dbManager.database;
    final results = await db.query(
      DatabaseConstants.tableUserPreferences,
      where: '${DatabaseConstants.columnKey} = ?',
      whereArgs: [_migrationKey],
    );
    
    if (results.isEmpty) return false;
    
    final value = results.first[DatabaseConstants.columnValue] as String;
    return value == 'true';
  }

  /// Sets the migration completion flag.
  Future<void> _setMigrated() async {
    final db = await _dbManager.database;
    await db.insert(
      DatabaseConstants.tableUserPreferences,
      {
        DatabaseConstants.columnKey: _migrationKey,
        DatabaseConstants.columnValue: 'true',
        DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Runs the migration process if needed.
  /// 
  /// Returns true if migration was performed, false if already migrated.
  Future<bool> migrateIfNeeded(MockDataProvider mockData) async {
    if (await hasMigrated()) {
      debugPrint('Mock data already migrated to SQLite.');
      return false;
    }

    debugPrint('Starting migration from MockDataProvider to SQLite...');
    
    try {
      // 1. Migrate clothing items
      final items = mockData.getAllItems();
      debugPrint('Migrating ${items.length} clothing items...');
      
      // Batch create uses a transaction internally
      await _clothingRepository.batchCreate(items);
      
      // 2. Migrate outfits
      final outfits = mockData.getAllOutfits();
      debugPrint('Migrating ${outfits.length} outfits...');
      for (final outfit in outfits) {
        await _outfitRepository.create(outfit);
        
        // If outfit has an assigned date, migrate the assignment
        if (outfit.assignedDate != null) {
          await _outfitRepository.assignToDate(outfit.id, outfit.assignedDate!);
        }
      }
      
      // Mark as migrated
      await _setMigrated();
      debugPrint('Data migration completed successfully.');
      return true;
    } catch (e) {
      debugPrint('Error during data migration: $e');
      // If there's an error, we don't set the flag so it can retry next time
      return false;
    }
  }
}
