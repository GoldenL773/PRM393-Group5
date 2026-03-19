import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_runner.dart';

/// DatabaseManager is a singleton class that manages the SQLite database connection
/// and lifecycle for the GoldFit application.
///
/// This class handles:
/// - Database initialization on first access
/// - Connection management with singleton pattern
/// - Foreign key constraint enforcement
/// - WAL (Write-Ahead Logging) mode for concurrent access
/// - Database versioning and migration coordination
///
/// Usage:
/// ```dart
/// final dbManager = DatabaseManager();
/// final db = await dbManager.database;
/// ```
class DatabaseManager {
  // Singleton instance
  static final DatabaseManager _instance = DatabaseManager._internal();

  // Private database instance
  static Database? _database;

  // Private constructor for singleton pattern
  DatabaseManager._internal();

  /// Factory constructor returns the singleton instance
  factory DatabaseManager() => _instance;

  /// Factory constructor for testing that uses a provided database instance
  ///
  /// This constructor is used in tests to inject a test database instance
  /// instead of creating a real database file.
  ///
  /// Parameters:
  /// - testDatabase: The test database instance to use
  factory DatabaseManager.forTesting(Database testDatabase) {
    _database = testDatabase;
    return _instance;
  }

  /// Gets the database instance, initializing it on first access
  ///
  /// Returns a Future<Database> that resolves to the initialized database.
  /// If the database is already initialized, returns the existing instance.
  /// Otherwise, initializes the database by calling _initDatabase.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database with proper configuration
  ///
  /// This method:
  /// 1. Resolves the database path using getDatabasesPath()
  /// 2. Opens the database with the configured name and version
  /// 3. Sets up onCreate, onUpgrade, and onConfigure callbacks
  ///
  /// Returns a Future<Database> with the initialized database instance.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configures database settings before any operations
  ///
  /// This method is called before onCreate or onUpgrade.
  /// It enables:
  /// - Foreign key constraints for referential integrity
  /// - WAL (Write-Ahead Logging) mode for concurrent read/write operations
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys to enforce referential integrity
    await db.execute('PRAGMA foreign_keys = ON');

    // Enable WAL mode for better concurrent access performance
    // WAL allows multiple readers and one writer to operate simultaneously
    await db.rawQuery('PRAGMA journal_mode = WAL');
  }

  /// Called when the database is created for the first time
  ///
  /// This method will execute all migration scripts from version 0 to the
  /// current version to create the initial schema.
  ///
  /// Parameters:
  /// - db: The database instance
  /// - version: The target database version
  Future<void> _onCreate(Database db, int version) async {
    await MigrationRunner.runMigrations(db, 0, version);
  }

  /// Called when the database needs to be upgraded to a new version
  ///
  /// This method executes migration scripts from the old version to the new version.
  ///
  /// Parameters:
  /// - db: The database instance
  /// - oldVersion: The current database version
  /// - newVersion: The target database version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await MigrationRunner.runMigrations(db, oldVersion, newVersion);
  }

  /// Closes the database connection
  ///
  /// This method should be called when the database is no longer needed,
  /// typically when the app is shutting down.
  ///
  /// After calling this method, the next call to `database` getter will
  /// reinitialize the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
