import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Initial database schema migration (version 1).
/// Creates all tables, foreign keys, and indexes for the GoldFit application.
class MigrationV1 implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> migrate(Database db) async {
    // Create all tables
    await _createClothingItemsTable(db);
    await _createOutfitsTable(db);
    await _createOutfitItemsTable(db);
    await _createOutfitCalendarTable(db);
    await _createUsageHistoryTable(db);
    await _createBasePhotosTable(db);
    await _createTryOnSessionsTable(db);
    await _createUserPreferencesTable(db);
    await _createTagsTable(db);
    await _createClothingTagsTable(db);

    // Create all indexes
    await _createIndexes(db);
  }

  /// Creates the clothing_items table with all columns.
  /// Stores individual clothing items with their properties.
  Future<void> _createClothingItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableClothingItems} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnImagePath} TEXT NOT NULL,
        ${DatabaseConstants.columnType} TEXT NOT NULL,
        ${DatabaseConstants.columnColor} TEXT NOT NULL,
        ${DatabaseConstants.columnSeasons} TEXT NOT NULL,
        ${DatabaseConstants.columnPrice} REAL,
        ${DatabaseConstants.columnUsageCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnIsFavorite} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnAiTags} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the outfits table with all columns.
  /// Stores outfit combinations with metadata.
  Future<void> _createOutfitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableOutfits} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnVibe} TEXT,
        ${DatabaseConstants.columnThumbnailPath} TEXT,
        ${DatabaseConstants.columnWeatherContext} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the outfit_items junction table.
  /// Links clothing items to outfits with layer ordering.
  Future<void> _createOutfitItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableOutfitItems} (
        ${DatabaseConstants.columnOutfitId} TEXT NOT NULL,
        ${DatabaseConstants.columnClothingItemId} TEXT NOT NULL,
        ${DatabaseConstants.columnLayerOrder} INTEGER NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.columnOutfitId}, ${DatabaseConstants.columnClothingItemId}),
        FOREIGN KEY (${DatabaseConstants.columnOutfitId}) 
          REFERENCES ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnClothingItemId}) 
          REFERENCES ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE
      )
    ''');
  }

  /// Creates the outfit_calendar table.
  /// Tracks outfit assignments to specific dates with unique constraint.
  Future<void> _createOutfitCalendarTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableOutfitCalendar} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnOutfitId} TEXT NOT NULL,
        ${DatabaseConstants.columnAssignedDate} INTEGER NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnOutfitId}) 
          REFERENCES ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        UNIQUE(${DatabaseConstants.columnAssignedDate})
      )
    ''');
  }

  /// Creates the usage_history table.
  /// Records when clothing items are worn.
  Future<void> _createUsageHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableUsageHistory} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnClothingItemId} TEXT NOT NULL,
        ${DatabaseConstants.columnOutfitId} TEXT,
        ${DatabaseConstants.columnWornDate} INTEGER NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnClothingItemId}) 
          REFERENCES ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnOutfitId}) 
          REFERENCES ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnId}) 
          ON DELETE SET NULL
      )
    ''');
  }

  /// Creates the base_photos table.
  /// Stores user photos for virtual try-on feature.
  Future<void> _createBasePhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableBasePhotos} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnImagePath} TEXT NOT NULL,
        ${DatabaseConstants.columnIsActive} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the try_on_sessions table.
  /// Records virtual try-on sessions with results.
  Future<void> _createTryOnSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTryOnSessions} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnBasePhotoId} TEXT NOT NULL,
        ${DatabaseConstants.columnOutfitId} TEXT,
        ${DatabaseConstants.columnMode} TEXT NOT NULL,
        ${DatabaseConstants.columnResultImagePath} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnBasePhotoId}) 
          REFERENCES ${DatabaseConstants.tableBasePhotos}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnOutfitId}) 
          REFERENCES ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnId}) 
          ON DELETE SET NULL
      )
    ''');
  }

  /// Creates the user_preferences table.
  /// Stores user settings and preferences as key-value pairs.
  Future<void> _createUserPreferencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableUserPreferences} (
        ${DatabaseConstants.columnKey} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnValue} TEXT NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the tags table.
  /// Stores tags that can be applied to clothing items.
  Future<void> _createTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTags} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.columnCategory} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL
      )
    ''');
  }

  /// Creates the clothing_tags junction table.
  /// Links tags to clothing items.
  Future<void> _createClothingTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableClothingTags} (
        ${DatabaseConstants.columnClothingItemId} TEXT NOT NULL,
        ${DatabaseConstants.columnTagId} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.columnClothingItemId}, ${DatabaseConstants.columnTagId}),
        FOREIGN KEY (${DatabaseConstants.columnClothingItemId}) 
          REFERENCES ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnTagId}) 
          REFERENCES ${DatabaseConstants.tableTags}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE
      )
    ''');
  }

  /// Creates all indexes for optimizing query performance.
  /// Indexes are created on frequently queried columns and foreign keys.
  Future<void> _createIndexes(Database db) async {
    // Clothing items indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexClothingType} 
      ON ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnType})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexClothingColor} 
      ON ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnColor})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexClothingCreated} 
      ON ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnCreatedAt})
    ''');

    // Outfits indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexOutfitVibe} 
      ON ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnVibe})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexOutfitCreated} 
      ON ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnCreatedAt})
    ''');

    // Outfit items indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexOutfitItemsOutfit} 
      ON ${DatabaseConstants.tableOutfitItems}(${DatabaseConstants.columnOutfitId})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexOutfitItemsItem} 
      ON ${DatabaseConstants.tableOutfitItems}(${DatabaseConstants.columnClothingItemId})
    ''');

    // Outfit calendar indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCalendarDate} 
      ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnAssignedDate})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCalendarOutfit} 
      ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnOutfitId})
    ''');

    // Usage history indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexUsageItem} 
      ON ${DatabaseConstants.tableUsageHistory}(${DatabaseConstants.columnClothingItemId})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexUsageDate} 
      ON ${DatabaseConstants.tableUsageHistory}(${DatabaseConstants.columnWornDate})
    ''');

    // Base photos indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexBasePhotoActive} 
      ON ${DatabaseConstants.tableBasePhotos}(${DatabaseConstants.columnIsActive})
    ''');

    // Try-on sessions indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexSessionBasePhoto} 
      ON ${DatabaseConstants.tableTryOnSessions}(${DatabaseConstants.columnBasePhotoId})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexSessionCreated} 
      ON ${DatabaseConstants.tableTryOnSessions}(${DatabaseConstants.columnCreatedAt})
    ''');

    // Tags indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexTagCategory} 
      ON ${DatabaseConstants.tableTags}(${DatabaseConstants.columnCategory})
    ''');

    // Clothing tags indexes
    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexClothingTagsItem} 
      ON ${DatabaseConstants.tableClothingTags}(${DatabaseConstants.columnClothingItemId})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexClothingTagsTag} 
      ON ${DatabaseConstants.tableClothingTags}(${DatabaseConstants.columnTagId})
    ''');
  }
}
