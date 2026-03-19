import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/core/database/database_exceptions.dart';

void main() {
  group('DatabaseException', () {
    test('creates exception with message only', () {
      final exception = DatabaseException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.operation, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with operation and cause', () {
      final cause = Exception('Root cause');
      final exception = DatabaseException(
        'Test error',
        operation: 'insert',
        cause: cause,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.operation, equals('insert'));
      expect(exception.cause, equals(cause));
    });

    test('toString includes operation when present', () {
      final exception = DatabaseException(
        'Test error',
        operation: 'update',
      );

      expect(
        exception.toString(),
        equals('DatabaseException: Test error (operation: update)'),
      );
    });

    test('toString excludes operation when not present', () {
      final exception = DatabaseException('Test error');

      expect(exception.toString(), equals('DatabaseException: Test error'));
    });
  });

  group('MigrationException', () {
    test('creates exception with version information', () {
      final exception = MigrationException(
        'Migration failed',
        fromVersion: 1,
        toVersion: 2,
      );

      expect(exception.message, equals('Migration failed'));
      expect(exception.fromVersion, equals(1));
      expect(exception.toVersion, equals(2));
      expect(exception.operation, equals('migration'));
    });

    test('includes cause when provided', () {
      final cause = Exception('SQL error');
      final exception = MigrationException(
        'Migration failed',
        fromVersion: 1,
        toVersion: 2,
        cause: cause,
      );

      expect(exception.cause, equals(cause));
    });

    test('extends DatabaseException', () {
      final exception = MigrationException(
        'Migration failed',
        fromVersion: 1,
        toVersion: 2,
      );

      expect(exception, isA<DatabaseException>());
    });
  });

  group('ValidationException', () {
    test('creates exception with validation errors', () {
      final errors = {
        'name': 'Name is required',
        'email': 'Invalid email format',
      };
      final exception = ValidationException('Validation failed', errors);

      expect(exception.message, equals('Validation failed'));
      expect(exception.errors, equals(errors));
      expect(exception.operation, equals('validation'));
    });

    test('extends DatabaseException', () {
      final exception = ValidationException('Validation failed', {});

      expect(exception, isA<DatabaseException>());
    });
  });

  group('ConcurrencyException', () {
    test('creates exception with message', () {
      final exception = ConcurrencyException('Concurrent modification detected');

      expect(exception.message, equals('Concurrent modification detected'));
      expect(exception.operation, equals('concurrent_access'));
    });

    test('includes cause when provided', () {
      final cause = Exception('Lock timeout');
      final exception = ConcurrencyException(
        'Concurrent modification detected',
        cause: cause,
      );

      expect(exception.cause, equals(cause));
    });

    test('extends DatabaseException', () {
      final exception = ConcurrencyException('Concurrent modification detected');

      expect(exception, isA<DatabaseException>());
    });
  });
}
