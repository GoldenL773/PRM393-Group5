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
    
    // 3. Copy existing data (defaults to 'morning' via table definition, but we specify it to be safe)
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
    
    // 4. Drop the old table
    await db.execute('DROP TABLE outfit_calendar_old');
    
    // The indexes on assignedDate and outfitId for this table were dropped when the table was renamed
    // or they still point to the old table space theoretically. Let's recreate them just to be safe.
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
  }
}
