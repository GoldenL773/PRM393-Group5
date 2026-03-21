import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Database schema migration (version 4).
/// Adds the is_favorite column to the clothing_items table.
class MigrationV4 implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> migrate(Database db) async {
    // Check if column exists to safely migrate
    var tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConstants.tableClothingItems})');
    bool columnExists = tableInfo.any((column) => column['name'] == DatabaseConstants.columnIsFavorite);

    if (!columnExists) {
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableClothingItems} 
        ADD COLUMN ${DatabaseConstants.columnIsFavorite} INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }
}
