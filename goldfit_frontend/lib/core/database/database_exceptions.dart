/// Custom exception types for database operations.
///
/// This file defines a hierarchy of exceptions used throughout the database
/// layer for proper error handling and reporting.
library;

/// Base exception class for all database-related errors.
///
/// This exception includes context about the operation that failed and
/// the underlying cause of the error.
class DatabaseException implements Exception {
  /// Human-readable error message
  final String message;

  /// The database operation that failed (e.g., 'insert', 'update', 'query')
  final String? operation;

  /// The underlying cause of the error (e.g., SQLException)
  final dynamic cause;

  DatabaseException(this.message, {this.operation, this.cause});

  @override
  String toString() =>
      'DatabaseException: $message${operation != null ? ' (operation: $operation)' : ''}';
}

/// Exception thrown when a database migration fails.
///
/// This exception includes information about the migration versions involved
/// to help diagnose migration issues.
class MigrationException extends DatabaseException {
  /// The database version before the migration
  final int fromVersion;

  /// The target database version
  final int toVersion;

  MigrationException(
    super.message, {
    required this.fromVersion,
    required this.toVersion,
    super.cause,
  }) : super(operation: 'migration');
}

/// Exception thrown when data validation fails.
///
/// This exception includes a map of field-specific validation errors
/// to provide detailed feedback about what validation rules were violated.
class ValidationException extends DatabaseException {
  /// Map of field names to validation error messages
  final Map<String, String> errors;

  ValidationException(super.message, this.errors)
      : super(operation: 'validation');
}

/// Exception thrown when a concurrency conflict occurs.
///
/// This exception is used when multiple operations attempt to modify
/// the same data simultaneously, causing a conflict.
class ConcurrencyException extends DatabaseException {
  ConcurrencyException(super.message, {super.cause})
      : super(operation: 'concurrent_access');
}
