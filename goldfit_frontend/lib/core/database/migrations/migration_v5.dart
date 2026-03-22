import 'package:sqflite/sqflite.dart';
import 'package:goldfit_frontend/core/database/migrations/migration.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';

/// Migration V5: Add authentication tables
class MigrationV5 implements Migration {
  @override
  int get version => 5;

  @override
  Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      // Create users table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableUsers} (
          ${DatabaseConstants.columnUserId} TEXT PRIMARY KEY,
          ${DatabaseConstants.columnEmail} TEXT NOT NULL UNIQUE,
          ${DatabaseConstants.columnDisplayName} TEXT,
          ${DatabaseConstants.columnPhotoUrl} TEXT,
          ${DatabaseConstants.columnAuthProvider} TEXT NOT NULL,
          ${DatabaseConstants.columnLastLoginAt} INTEGER,
          ${DatabaseConstants.columnEmailVerified} INTEGER DEFAULT 0,
          ${DatabaseConstants.columnPasswordHash} TEXT,
          ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
          ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
        )
      ''');

      // Create user_sessions table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableUserSessions} (
          ${DatabaseConstants.columnSessionId} TEXT PRIMARY KEY,
          ${DatabaseConstants.columnUserId} TEXT NOT NULL,
          ${DatabaseConstants.columnSessionToken} TEXT NOT NULL UNIQUE,
          ${DatabaseConstants.columnExpiresAt} INTEGER NOT NULL,
          ${DatabaseConstants.columnIsRevoked} INTEGER DEFAULT 0,
          ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
          FOREIGN KEY (${DatabaseConstants.columnUserId}) 
            REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
            ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexUsersEmail} 
        ON ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnEmail})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexUsersProvider} 
        ON ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnAuthProvider})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexSessionsUser} 
        ON ${DatabaseConstants.tableUserSessions}(${DatabaseConstants.columnUserId})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexSessionsToken} 
        ON ${DatabaseConstants.tableUserSessions}(${DatabaseConstants.columnSessionToken})
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS ${DatabaseConstants.indexSessionsExpiry} 
        ON ${DatabaseConstants.tableUserSessions}(${DatabaseConstants.columnExpiresAt})
      ''');
    });
  }
}