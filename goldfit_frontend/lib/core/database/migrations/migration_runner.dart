import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v1.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v2.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v3.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v5.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v6.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v7.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v8.dart'; // THÊM

class MigrationRunner {
  static final List<Migration> _migrations = [
    MigrationV1(),
    MigrationV2(),
    MigrationV3(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
    MigrationV8(), // THÊM
  ];

  static Future<void> runMigrations(
      Database db,
      int fromVersion,
      int toVersion,
      ) async {
    print('🔧 Running migrations from $fromVersion to $toVersion');

    for (final migration in _migrations) {
      if (migration.version > fromVersion && migration.version <= toVersion) {
        print('📦 Running migration V${migration.version}');
        await migration.migrate(db);
        print('✅ Migration V${migration.version} completed');
      }
    }

    print('✅ All migrations completed');
  }
}