import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Migration to version 3: Adds cleaned_image_path to clothing_items table.
class MigrationV3 extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> migrate(Database db) async {
    // Add cleaned_image_path column to clothing_items table
    await db.execute('ALTER TABLE ${DatabaseConstants.tableClothingItems} ADD COLUMN ${DatabaseConstants.columnCleanedImagePath} TEXT');
  }
}
