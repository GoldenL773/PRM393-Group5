import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Migration V6: Add user_id to clothing_items and outfits tables
class MigrationV6 implements Migration {
  @override
  int get version => 6;

  @override
  Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      // Check if column exists before adding
      final columns = await txn.rawQuery('PRAGMA table_info(${DatabaseConstants.tableClothingItems})');
      final hasUserId = columns.any((col) => col['name'] == DatabaseConstants.columnUserId);

      if (!hasUserId) {
        await txn.execute('''
          ALTER TABLE ${DatabaseConstants.tableClothingItems} 
          ADD COLUMN ${DatabaseConstants.columnUserId} TEXT
        ''');

        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_clothing_user 
          ON ${DatabaseConstants.tableClothingItems}(${DatabaseConstants.columnUserId})
        ''');
      }

      // Add to outfits table
      final outfitColumns = await txn.rawQuery('PRAGMA table_info(${DatabaseConstants.tableOutfits})');
      final hasOutfitUserId = outfitColumns.any((col) => col['name'] == DatabaseConstants.columnUserId);

      if (!hasOutfitUserId) {
        await txn.execute('''
          ALTER TABLE ${DatabaseConstants.tableOutfits} 
          ADD COLUMN ${DatabaseConstants.columnUserId} TEXT
        ''');

        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_outfits_user 
          ON ${DatabaseConstants.tableOutfits}(${DatabaseConstants.columnUserId})
        ''');
      }
    });
  }
}