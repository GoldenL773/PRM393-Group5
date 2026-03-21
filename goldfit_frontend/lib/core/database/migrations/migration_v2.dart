import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Migration to version 2: Adds try-on result fields to the outfits table.
class MigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> migrate(Database db) async {
    // Add columns to outfits table
    await db.execute('ALTER TABLE ${DatabaseConstants.tableOutfits} ADD COLUMN is_favorite INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE ${DatabaseConstants.tableOutfits} ADD COLUMN model_image_path TEXT');
    await db.execute('ALTER TABLE ${DatabaseConstants.tableOutfits} ADD COLUMN result_image_path TEXT');
  }
}
