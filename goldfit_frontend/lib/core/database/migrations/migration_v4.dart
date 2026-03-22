import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';

/// Migration to version 4: Adds collection management tables.
class MigrationV4 extends Migration {
  @override
  int get version => 4;

  @override
  Future<void> migrate(Database db) async {
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
