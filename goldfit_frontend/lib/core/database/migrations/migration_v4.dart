import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Version 4 migration.
/// Adds time_slot, event_name, and start_time to outfit_calendar table.
/// Changes the UNIQUE constraint from just assigned_date to (assigned_date, time_slot).
class MigrationV4 implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> migrate(Database db) async {
    // 1. Migrate outfit_calendar table (add columns, change UNIQUE constraint)
    // SQLite doesn't support dropping/modifying constraints easily
    // So we recreate the table and copy data

    // 1. Rename old table
    await db.execute('ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} RENAME TO outfit_calendar_old');

    // 2. Create new table with new columns and updated constraints
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableOutfitCalendar} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnOutfitId} TEXT NOT NULL,
        ${DatabaseConstants.columnAssignedDate} INTEGER NOT NULL,
        ${DatabaseConstants.columnTimeSlot} TEXT NOT NULL DEFAULT 'morning',
        ${DatabaseConstants.columnEventName} TEXT,
        ${DatabaseConstants.columnStartTime} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnOutfitId}) 
          REFERENCES ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnId}) 
          ON DELETE CASCADE,
        UNIQUE(${DatabaseConstants.columnAssignedDate}, ${DatabaseConstants.columnTimeSlot})
      )
    ''');

    // 1.3 Copy existing data (defaults to 'morning' via table definition, but we specify it to be safe)
    await db.execute('''
      INSERT INTO ${DatabaseConstants.tableOutfitCalendar} (
        ${DatabaseConstants.columnId},
        ${DatabaseConstants.columnOutfitId},
        ${DatabaseConstants.columnAssignedDate},
        ${DatabaseConstants.columnTimeSlot},
        ${DatabaseConstants.columnCreatedAt}
      )
      SELECT 
        ${DatabaseConstants.columnId},
        ${DatabaseConstants.columnOutfitId},
        ${DatabaseConstants.columnAssignedDate},
        'morning',
        ${DatabaseConstants.columnCreatedAt}
      FROM outfit_calendar_old
    ''');

    // Drop the old table
    await db.execute('DROP TABLE outfit_calendar_old');

    // Drop old indexes if they exist (to be recreated for the new table)
    await db.execute('DROP INDEX IF EXISTS ${DatabaseConstants.indexCalendarDate}');
    await db.execute('DROP INDEX IF EXISTS ${DatabaseConstants.indexCalendarOutfit}');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCalendarDate} 
      ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnAssignedDate})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCalendarOutfit} 
      ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnOutfitId})
    ''');

    // 2. Safely add is_favorite column to clothing_items table, only if it doesn't already exist
    var tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConstants.tableClothingItems})');
    bool columnExists = tableInfo.any((column) => column['name'] == DatabaseConstants.columnIsFavorite);

    if (!columnExists) {
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableClothingItems} 
        ADD COLUMN ${DatabaseConstants.columnIsFavorite} INTEGER NOT NULL DEFAULT 0
      ''');
    }

    // 3. Create collection management tables

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableCollections} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableCollectionItems} (
        ${DatabaseConstants.columnCollectionId} TEXT NOT NULL,
        ${DatabaseConstants.columnClothingItemId} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.columnCollectionId}, ${DatabaseConstants.columnClothingItemId}),
        FOREIGN KEY (${DatabaseConstants.columnCollectionId})
          REFERENCES ${DatabaseConstants.tableCollections}(${DatabaseConstants.columnId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.columnClothingItemId})
          REFERENCES ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCollectionCreated}
      ON ${DatabaseConstants.tableCollections}(${DatabaseConstants.columnCreatedAt})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCollectionItemsCollection}
      ON ${DatabaseConstants.tableCollectionItems}(${DatabaseConstants.columnCollectionId})
    ''');

    await db.execute('''
      CREATE INDEX ${DatabaseConstants.indexCollectionItemsItem}
      ON ${DatabaseConstants.tableCollectionItems}(${DatabaseConstants.columnClothingItemId})
    ''');
  }
}
