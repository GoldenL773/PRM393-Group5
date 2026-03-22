import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Migration to version 7: Ensures collection tables exist.
/// This acts as a safeguard in case MigrationV4 was interrupted or skipped.
class MigrationV7 extends Migration {
  @override
  int get version => 7;

  @override
  Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
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

      // Recreate indexes safely
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
    });
  }
}
