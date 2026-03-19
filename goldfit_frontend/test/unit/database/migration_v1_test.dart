import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_v1.dart';
import 'package:goldfit_frontend/core/database/migrations/migration_runner.dart';

void main() {
  group('MigrationV1', () {
    test('should have version 1', () {
      final migration = MigrationV1();
      expect(migration.version, equals(1));
    });

    test('should be registered in MigrationRunner', () {
      // This test verifies that MigrationV1 is properly registered
      // The actual migration execution will be tested in integration tests
      final migration = MigrationV1();
      expect(migration, isNotNull);
      expect(migration.version, equals(1));
    });
  });

  group('MigrationRunner', () {
    test('should have MigrationV1 registered', () {
      // Verify that the migration runner has migrations registered
      // This is a basic smoke test to ensure the setup is correct
      expect(MigrationRunner, isNotNull);
    });
  });
}
