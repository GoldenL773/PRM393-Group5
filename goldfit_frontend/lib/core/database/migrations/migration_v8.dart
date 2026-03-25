import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Migration V8: Adds time_slot, event_name, and start_time columns to the
/// outfit_calendar table if they do not already exist.
///
/// This is a remediation migration for devices that ran migrations V1–V3, V5–V7
/// but had MigrationV4 omitted from the runner, leaving the outfit_calendar
/// table without these three columns.
class MigrationV8 implements Migration {
  @override
  int get version => 8;

  @override
  Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      final calendarInfo = await txn.rawQuery(
        'PRAGMA table_info(${DatabaseConstants.tableOutfitCalendar})',
      );
      final existingColumns =
          calendarInfo.map((col) => col['name'] as String).toSet();

      // Add time_slot column (required for the new UNIQUE constraint)
      if (!existingColumns.contains(DatabaseConstants.columnTimeSlot)) {
        await txn.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar}
          ADD COLUMN ${DatabaseConstants.columnTimeSlot} TEXT NOT NULL DEFAULT 'morning'
        ''');
      }

      // Add event_name column (optional label for the calendar entry)
      if (!existingColumns.contains(DatabaseConstants.columnEventName)) {
        await txn.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar}
          ADD COLUMN ${DatabaseConstants.columnEventName} TEXT
        ''');
      }

      // Add start_time column (optional time string for the entry)
      if (!existingColumns.contains(DatabaseConstants.columnStartTime)) {
        await txn.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar}
          ADD COLUMN ${DatabaseConstants.columnStartTime} TEXT
        ''');
      }
    });
  }
}
