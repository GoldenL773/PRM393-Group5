import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v1.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v2.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v3.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v4.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v5.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v6.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v7.dart';

/// Manages and executes database migrations in sequential order.
class MigrationRunner {
  /// List of all available migrations, ordered by version.
  /// New migrations should be added to this list as they are created.
  static final List<Migration> _migrations = [
    MigrationV1(),
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
  ];

  /// Executes all migrations between [fromVersion] and [toVersion].
  ///
  /// Migrations are executed in ascending order by version number.
  /// Only migrations with version > fromVersion and version <= toVersion
  /// are executed.
  ///
  /// Example:
  /// - If fromVersion = 0 and toVersion = 3, migrations 1, 2, and 3 run
  /// - If fromVersion = 2 and toVersion = 4, migrations 3 and 4 run
  ///
  /// Throws an exception if any migration fails.
  static Future<void> runMigrations(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    for (final migration in _migrations) {
      if (migration.version > fromVersion && migration.version <= toVersion) {
        await migration.migrate(db);
      }
    }
  }
}
