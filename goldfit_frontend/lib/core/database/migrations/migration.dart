import 'package:sqflite/sqflite.dart';

/// Abstract base class for database migrations.
/// Each migration represents a versioned schema change.
abstract class Migration {
  /// The version number this migration upgrades to.
  int get version;

  /// Executes the migration on the provided database.
  /// This method should contain all DDL statements needed to upgrade
  /// the schema to this version.
  Future<void> migrate(Database db);
}
