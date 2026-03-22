import 'package:flutter/foundation.dart';
import 'package:goldfit_frontend/shared/providers/mock_data_provider.dart';
import 'package:goldfit_frontend/shared/repositories/clothing_repository.dart';
import 'package:goldfit_frontend/shared/repositories/outfit_repository.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Database seeder for development environment.
///
/// This class is responsible for clearing the database and populating it
/// with sample data. It should only be used in debug mode.
///
/// Validates Requirements: 13.1, 13.2, 13.3, 13.4, 13.5
class DatabaseSeeder {
  final DatabaseManager _dbManager;
  final ClothingRepository _clothingRepository;
  final OutfitRepository _outfitRepository;

  DatabaseSeeder(
    this._dbManager,
    this._clothingRepository,
    this._outfitRepository,
  );

  /// Clears the database and seeds it with mock data.
  ///
  /// Only runs if kDebugMode is true.
  Future<void> seed() async {
    if (!kDebugMode) {
      debugPrint('Database seeding is only allowed in debug mode.');
      return;
    }

    debugPrint('Starting database seeding...');

    try {
      await _clearDatabase();
      await _insertMockData();
      debugPrint('Database seeding completed successfully.');
    } catch (e) {
      debugPrint('Failed to seed database: $e');
      rethrow;
    }
  }

  /// Clears all data from the database.
  Future<void> _clearDatabase() async {
    final db = await _dbManager.database;

    await db.transaction((txn) async {
      // Order matters due to foreign keys
      await txn.delete(DatabaseConstants.tableClothingTags);
      await txn.delete(DatabaseConstants.tableTags);
      await txn.delete(DatabaseConstants.tableUsageHistory);
      await txn.delete(DatabaseConstants.tableOutfitCalendar);
      await txn.delete(DatabaseConstants.tableOutfitItems);
      await txn.delete(DatabaseConstants.tableCollectionItems);
      await txn.delete(DatabaseConstants.tableTryOnSessions);
      await txn.delete(DatabaseConstants.tableBasePhotos);
      await txn.delete(DatabaseConstants.tableOutfits);
      await txn.delete(DatabaseConstants.tableCollections);
      await txn.delete(DatabaseConstants.tableClothingItems);
      await txn.delete(DatabaseConstants.tableUserPreferences);
    });

    debugPrint('Database cleared.');
  }

  /// Generates and inserts mock data using MockDataProvider.
  Future<void> _insertMockData() async {
    // MockDataProvider generates its own data on initialization
    final mockData = MockDataProvider();

    // 1. Seed clothing items
    final items = mockData.getAllItems();
    debugPrint('Seeding ${items.length} clothing items...');
    await _clothingRepository.batchCreate(items);

    // 2. Seed outfits
    final outfits = mockData.getAllOutfits();
    debugPrint('Seeding ${outfits.length} outfits...');
    for (final outfit in outfits) {
      await _outfitRepository.create(outfit);

      if (outfit.assignedDate != null) {
        await _outfitRepository.assignToDate(outfit.id, outfit.assignedDate!, 'morning');
      }
    }
  }
}
