import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Migration to version 7:
/// - Ensures collection tables exist (safeguard for MigrationV4)
/// - Fixes outfit_calendar table by adding missing columns (time_slot, event_name, start_time)
class MigrationV7 extends Migration {
  @override
  int get version => 7;

  @override
  Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      // ========================================================================
      // PART 1: Fix outfit_calendar table - ADD MISSING COLUMNS
      // ========================================================================

      // Check if outfit_calendar table exists
      final tables = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConstants.tableOutfitCalendar}'"
      );

      if (tables.isNotEmpty) {
        // Get existing columns
        final columns = await txn.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.tableOutfitCalendar})'
        );
        final columnNames = columns.map((col) => col['name'] as String).toList();

        // Add time_slot column if missing
        if (!columnNames.contains(DatabaseConstants.columnTimeSlot)) {
          await txn.execute('''
            ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
            ADD COLUMN ${DatabaseConstants.columnTimeSlot} TEXT
          ''');

          // Set default value for existing rows
          await txn.execute('''
            UPDATE ${DatabaseConstants.tableOutfitCalendar}
            SET ${DatabaseConstants.columnTimeSlot} = 'morning'
            WHERE ${DatabaseConstants.columnTimeSlot} IS NULL
          ''');
        }

        // Add event_name column if missing
        if (!columnNames.contains(DatabaseConstants.columnEventName)) {
          await txn.execute('''
            ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
            ADD COLUMN ${DatabaseConstants.columnEventName} TEXT
          ''');
        }

        // Add start_time column if missing
        if (!columnNames.contains(DatabaseConstants.columnStartTime)) {
          await txn.execute('''
            ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
            ADD COLUMN ${DatabaseConstants.columnStartTime} TEXT
          ''');
        }

        // Add created_at column if missing
        if (!columnNames.contains(DatabaseConstants.columnCreatedAt)) {
          await txn.execute('''
            ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
            ADD COLUMN ${DatabaseConstants.columnCreatedAt} INTEGER
          ''');

          await txn.execute('''
            UPDATE ${DatabaseConstants.tableOutfitCalendar}
            SET ${DatabaseConstants.columnCreatedAt} = ${DateTime.now().millisecondsSinceEpoch}
            WHERE ${DatabaseConstants.columnCreatedAt} IS NULL
          ''');
        }

        // Add id column if missing (primary key)
        if (!columnNames.contains(DatabaseConstants.columnId)) {
          // SQLite doesn't support adding primary key column easily
          // Log warning and suggest clearing database if needed
          print('⚠️ Warning: ${DatabaseConstants.columnId} column missing in outfit_calendar');
          print('   Consider clearing database to fix schema');
        }
      }

      // ========================================================================
      // PART 2: Ensure collections tables exist (safeguard for MigrationV4)
      // ========================================================================

      // Create collections table if not exists
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableCollections} (
          ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
          ${DatabaseConstants.columnName} TEXT NOT NULL,
          ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
          ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
        )
      ''');

      // Create collection_items table if not exists
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableCollectionItems} (
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

      // Create indexes for collections
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexCollectionCreated}
        ON ${DatabaseConstants.tableCollections}(${DatabaseConstants.columnCreatedAt})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexCollectionItemsCollection}
        ON ${DatabaseConstants.tableCollectionItems}(${DatabaseConstants.columnCollectionId})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexCollectionItemsItem}
        ON ${DatabaseConstants.tableCollectionItems}(${DatabaseConstants.columnClothingItemId})
      ''');

      // ========================================================================
      // PART 3: Ensure outfit_calendar indexes exist
      // ========================================================================

      // Create outfit_calendar indexes if they don't exist
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexCalendarDate}
        ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnAssignedDate})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexCalendarOutfit}
        ON ${DatabaseConstants.tableOutfitCalendar}(${DatabaseConstants.columnOutfitId})
      ''');
    });
  }
}