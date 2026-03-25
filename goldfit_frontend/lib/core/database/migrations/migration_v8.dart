import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Migration V8: Add missing columns to outfit_calendar
class MigrationV8 implements Migration {
  @override
  int get version => 8;

  @override
  Future<void> migrate(Database db) async {
    print('🔧 Migration V8: Fixing outfit_calendar table');

    // Kiểm tra bảng outfit_calendar có tồn tại không
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConstants.tableOutfitCalendar}'"
    );

    if (tables.isEmpty) {
      print('Creating outfit_calendar table...');
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
            ON DELETE CASCADE
        )
      ''');
      print('✅ outfit_calendar table created');
    } else {
      // Lấy danh sách cột hiện có
      final columns = await db.rawQuery(
          'PRAGMA table_info(${DatabaseConstants.tableOutfitCalendar})'
      );
      final columnNames = columns.map((c) => c['name'] as String).toList();

      print('Current columns: $columnNames');

      // Thêm time_slot nếu thiếu
      if (!columnNames.contains(DatabaseConstants.columnTimeSlot)) {
        await db.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
          ADD COLUMN ${DatabaseConstants.columnTimeSlot} TEXT NOT NULL DEFAULT 'morning'
        ''');
        print('✅ Added column: ${DatabaseConstants.columnTimeSlot}');
      }

      // Thêm event_name nếu thiếu
      if (!columnNames.contains(DatabaseConstants.columnEventName)) {
        await db.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
          ADD COLUMN ${DatabaseConstants.columnEventName} TEXT
        ''');
        print('✅ Added column: ${DatabaseConstants.columnEventName}');
      }

      // Thêm start_time nếu thiếu
      if (!columnNames.contains(DatabaseConstants.columnStartTime)) {
        await db.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
          ADD COLUMN ${DatabaseConstants.columnStartTime} TEXT
        ''');
        print('✅ Added column: ${DatabaseConstants.columnStartTime}');
      }

      // Thêm created_at nếu thiếu
      if (!columnNames.contains(DatabaseConstants.columnCreatedAt)) {
        await db.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfitCalendar} 
          ADD COLUMN ${DatabaseConstants.columnCreatedAt} INTEGER
        ''');

        // Set default value
        await db.execute('''
          UPDATE ${DatabaseConstants.tableOutfitCalendar}
          SET ${DatabaseConstants.columnCreatedAt} = ${DateTime.now().millisecondsSinceEpoch}
          WHERE ${DatabaseConstants.columnCreatedAt} IS NULL
        ''');
        print('✅ Added column: ${DatabaseConstants.columnCreatedAt}');
      }

      // Kiểm tra lại sau khi thêm
      final updatedColumns = await db.rawQuery(
          'PRAGMA table_info(${DatabaseConstants.tableOutfitCalendar})'
      );
      print('Updated columns: ${updatedColumns.map((c) => c['name'])}');
    }

    print('🎉 Migration V8 completed');
  }
}